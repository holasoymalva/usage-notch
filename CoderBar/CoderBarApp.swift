//
//  CoderBarApp.swift
//  Usage Notch
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            NotchOverlayController.shared.showWindow()
            // Initial sync if keys are present
            await APIUsageService.shared.syncAllServices()
        }
    }
}

@main
struct CoderBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var usageManager = UsageManager.shared
    @StateObject private var apiService = APIUsageService.shared
    
    var body: some Scene {
        // Menu Bar Companion
        MenuBarExtra("Usage Notch", systemImage: "sparkles") {
            VStack(alignment: .leading) {
                Text("Usage Notch")
                    .font(.headline)
                
                Divider()
                
                ForEach(usageManager.providers.filter { $0.isEnabled }) { item in
                    HStack {
                        Text("\(item.id.displayName):")
                        Spacer()
                        Text("\(Int(item.primaryUsedPercent))%")
                            .fontWeight(.bold)
                    }
                }
                
                Divider()
                
                Button(action: {
                    Task {
                        await apiService.syncAllServices()
                    }
                }) {
                    Text("Sincronizar APIs Ahora")
                }
                
                Button(usageManager.isHudVisible ? "Ocultar Notch" : "Mostrar Notch") {
                    usageManager.isHudVisible.toggle()
                }
                
                Divider()
                
                Button("Preferencias...") {
                    SettingsWindowController.shared.showSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Button("Salir de Usage Notch") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
    }
}
