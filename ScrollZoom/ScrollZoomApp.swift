//
//  ScrollZoomApp.swift
//  ScrollZoom
//

import SwiftUI

@main
struct ScrollZoomApp: App {
    @StateObject private var permissionManager = PermissionManager()
    @StateObject private var eventMonitor = EventMonitor()
    @State private var sensitivity: Double = 0.02

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 8) {
                // Permission status
                if !permissionManager.isAccessibilityGranted {
                    Button("Grant Accessibility Permission") {
                        permissionManager.requestAccessibility()
                    }
                    Divider()
                }

                // Enable/Disable toggle
                Toggle(isOn: $eventMonitor.isEnabled) {
                    Text(eventMonitor.isEnabled ? "Enabled" : "Disabled")
                }
                .toggleStyle(.switch)
                .disabled(!permissionManager.isAccessibilityGranted)

                Divider()

                // Sensitivity slider
                Text("Sensitivity: \(String(format: "%.3f", sensitivity))")
                Slider(value: $sensitivity, in: 0.005...0.1, step: 0.005)
                    .frame(width: 150)
                    .onChange(of: sensitivity) { _, newValue in
                        eventMonitor.sensitivity = newValue
                    }

                Divider()

                // Quit button
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding()
            .frame(width: 200)
        } label: {
            Image(systemName: eventMonitor.isEnabled ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
        }
        .menuBarExtraStyle(.window)
    }
}
