//
//  PermissionManager.swift
//  ScrollZoom
//

import Foundation
import Combine
import ApplicationServices
import AppKit

class PermissionManager: ObservableObject {
    @Published var isAccessibilityGranted: Bool = false
    private var timer: Timer?

    init() {
        checkAccessibility()
        // Periodically check for permission changes
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkAccessibility()
        }
    }

    deinit {
        timer?.invalidate()
    }

    func checkAccessibility() {
        let granted = AXIsProcessTrusted()
        if granted != isAccessibilityGranted {
            DispatchQueue.main.async {
                self.isAccessibilityGranted = granted
            }
        }
    }

    func requestAccessibility() {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        let trusted = AXIsProcessTrustedWithOptions(options)
        isAccessibilityGranted = trusted

        if !trusted {
            openAccessibilitySettings()
        }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
