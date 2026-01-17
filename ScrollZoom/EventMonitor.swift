//
//  EventMonitor.swift
//  ScrollZoom
//

import Foundation
import Combine
import CoreGraphics
import Cocoa

class EventMonitor: ObservableObject {
    @Published var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                start()
            } else {
                stop()
            }
        }
    }

    var sensitivity: Double = 0.02

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        guard eventTap == nil else { return }

        let eventMask: CGEventMask = (1 << CGEventType.scrollWheel.rawValue)

        // Create event tap
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }

                let monitor = Unmanaged<EventMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let eventTap = eventTap else {
            print("Failed to create event tap. Check Accessibility permissions.")
            isEnabled = false
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        print("Event monitor started")
    }

    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil

        print("Event monitor stopped")
    }

    private var gestureActive = false

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle tap disabled event
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap = eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        // Check if Command key is pressed
        let flags = event.flags
        guard flags.contains(.maskCommand) else {
            if gestureActive {
                // Send end gesture
                if let endEvent = createMagnifyEvent(magnification: 0, phase: 4, location: event.location) {
                    endEvent.tapPostEvent(proxy)
                }
                gestureActive = false
            }
            return Unmanaged.passRetained(event)
        }

        // Get scroll delta
        let deltaY = event.getDoubleValueField(.scrollWheelEventDeltaAxis1)

        // Skip if no significant scroll
        guard abs(deltaY) > 0.1 else {
            return Unmanaged.passRetained(event)
        }

        let magnification = deltaY * sensitivity
        let phase: Int64 = gestureActive ? 2 : 1

        // Create and post magnify event through the proxy
        if let magnifyEvent = createMagnifyEvent(magnification: magnification, phase: phase, location: event.location) {
            magnifyEvent.tapPostEvent(proxy)
        }

        if !gestureActive {
            gestureActive = true
        }

        // Consume the scroll event
        return nil
    }

    private func createMagnifyEvent(magnification: Double, phase: Int64, location: CGPoint) -> CGEvent? {
        guard let source = CGEventSource(stateID: .privateState) else { return nil }
        guard let event = CGEvent(source: source) else { return nil }

        event.type = CGEventType(rawValue: 30)!  // kCGEventMagnify
        event.location = location
        event.setDoubleValueField(CGEventField(rawValue: 113)!, value: magnification)
        event.setDoubleValueField(CGEventField(rawValue: 119)!, value: magnification)
        event.setIntegerValueField(CGEventField(rawValue: 132)!, value: phase)
        event.setIntegerValueField(CGEventField(rawValue: 115)!, value: 1)  // gesture subtype

        return event
    }

    deinit {
        stop()
    }
}
