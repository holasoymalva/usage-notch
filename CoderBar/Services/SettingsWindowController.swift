//
//  SettingsWindowController.swift
//  Usage Notch
//

import Cocoa
import SwiftUI

@MainActor
public final class SettingsWindowController: NSObject, NSWindowDelegate {
    public static let shared = SettingsWindowController()
    
    private var settingsWindow: NSWindow?
    
    public func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 460),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Preferencias - Usage Notch"
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        let hostingView = NSHostingView(rootView: SettingsView())
        window.contentView = hostingView
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func windowWillClose(_ notification: Notification) {
        // Keep reference or cleanup if needed
    }
}
