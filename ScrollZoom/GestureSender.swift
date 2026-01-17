//
//  GestureSender.swift
//  ScrollZoom
//

import Foundation
import CoreGraphics
import Cocoa

class GestureSender {
    private static var gesturePhase: Int = 0  // 0: none, 1: began, 2: ongoing
    private static var endTimer: Timer?

    static func sendMagnifyGesture(magnification: Double) {
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.main else { return }
        let cgPoint = CGPoint(x: mouseLocation.x, y: screen.frame.height - mouseLocation.y)

        endTimer?.invalidate()

        // Determine phase
        let phase: Int64
        if gesturePhase == 0 {
            phase = 1  // kCGGesturePhaseBegin
            gesturePhase = 1
            print("Magnify BEGIN: \(magnification)")
        } else {
            phase = 2  // kCGGesturePhaseChanged
            gesturePhase = 2
            print("Magnify CHANGED: \(magnification)")
        }

        // Create and post magnify event
        postMagnifyEvent(magnification: magnification, phase: phase, location: cgPoint)

        // Schedule end
        endTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
            print("Magnify END")
            postMagnifyEvent(magnification: 0, phase: 4, location: cgPoint)  // kCGGesturePhaseEnd
            gesturePhase = 0
        }
    }

    private static func postMagnifyEvent(magnification: Double, phase: Int64, location: CGPoint) {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            print("Failed to create event source")
            return
        }

        guard let event = CGEvent(source: source) else {
            print("Failed to create event")
            return
        }

        // Set event type to magnify (29 = NSEventTypeMagnify, 30 = kCGEventMagnify)
        event.type = CGEventType(rawValue: 30)!
        event.location = location

        // Set magnification value - try field 119 (kCGGestureMagnification) instead of 113
        event.setDoubleValueField(CGEventField(rawValue: 119)!, value: magnification)

        // Also try setting field 113 for compatibility
        event.setDoubleValueField(CGEventField(rawValue: 113)!, value: magnification)

        // Set gesture phase - field 132
        event.setIntegerValueField(CGEventField(rawValue: 132)!, value: phase)

        // Set gesture behavior - field 123
        event.setIntegerValueField(CGEventField(rawValue: 123)!, value: 1)

        // Post to session event tap for better compatibility
        event.post(tap: .cgSessionEventTap)

        print("Posted magnify event: mag=\(magnification), phase=\(phase), loc=\(location)")
    }
}
