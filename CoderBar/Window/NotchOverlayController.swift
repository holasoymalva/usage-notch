//
//  NotchOverlayController.swift
//  Usage Notch
//

import Cocoa
import SwiftUI
import Combine

final class FloatingOverlayPanel: NSPanel {
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}

final class PassthroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let manager = UsageManager.shared
        guard manager.isHudVisible else { return nil }
        
        // Convert from window coordinate space to view's local coordinate space
        let localPoint = convert(point, from: nil)
        let dockW: CGFloat = 78
        let count = CGFloat(manager.providers.filter { $0.isEnabled }.count + 1)
        let safeCount = max(1, count)
        let dockH = 48.0 + (safeCount * 64.0) + (max(0, safeCount - 1) * 16.0) + 48.0
        
        let isAnyPopoverOpen = manager.selectedProviderId != nil || manager.isSettingsPopoverOpen
        
        switch manager.position {
        case .leftEdge:
            // Check if point is inside the dock flap
            if localPoint.x >= 0 && localPoint.x <= dockW && localPoint.y >= 0 && localPoint.y <= dockH {
                return super.hitTest(point)
            }
            // Check if popover is visible and point is inside popover card
            if isAnyPopoverOpen {
                let popoverMinX: CGFloat = 66
                let popoverMaxX: CGFloat = 66 + 345
                if localPoint.x >= popoverMinX && localPoint.x <= popoverMaxX && localPoint.y >= 0 && localPoint.y <= bounds.height {
                    return super.hitTest(point)
                }
            }
            return nil
            
        case .rightEdge:
            let dockMinX = bounds.width - dockW
            if localPoint.x >= dockMinX && localPoint.x <= bounds.width && localPoint.y >= 0 && localPoint.y <= dockH {
                return super.hitTest(point)
            }
            if isAnyPopoverOpen {
                let popoverMaxX = bounds.width - 66
                let popoverMinX = bounds.width - 66 - 345
                if localPoint.x >= popoverMinX && localPoint.x <= popoverMaxX && localPoint.y >= 0 && localPoint.y <= bounds.height {
                    return super.hitTest(point)
                }
            }
            return nil
            
        case .topNotch:
            return super.hitTest(point)
        }
    }
}

@MainActor
public final class NotchOverlayController: NSObject {
    public static let shared = NotchOverlayController()
    
    private var overlayPanel: FloatingOverlayPanel?
    private var cancellables = Set<AnyCancellable>()
    private var globalClickMonitor: Any?
    
    public override init() {
        super.init()
        setupObservers()
        setupGlobalClickMonitor()
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .notchLayoutChanged)
            .sink { [weak self] _ in
                self?.repositionPanels()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .notchVisibilityChanged)
            .sink { [weak self] _ in
                self?.updateVisibility()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.repositionPanels()
            }
            .store(in: &cancellables)
    }
    
    // Auto-dismiss the popover when clicking elsewhere on the screen
    private func setupGlobalClickMonitor() {
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor [weak self] in
                guard let self = self,
                      let panel = self.overlayPanel,
                      panel.isVisible,
                      (UsageManager.shared.selectedProviderId != nil || UsageManager.shared.isSettingsPopoverOpen) else { return }
                
                let clickLocation = NSEvent.mouseLocation
                if !panel.frame.contains(clickLocation) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        UsageManager.shared.selectedProviderId = nil
                        UsageManager.shared.isSettingsPopoverOpen = false
                    }
                }
            }
        }
    }
    
    public func showWindow() {
        if overlayPanel == nil {
            createPanels()
        }
        repositionPanels()
        overlayPanel?.orderFrontRegardless()
    }
    
    public func hideWindow() {
        overlayPanel?.orderOut(nil)
    }
    
    public func expand() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            UsageManager.shared.selectedProviderId = UsageManager.shared.primaryUsage.id
        }
    }
    
    public func collapse() {
        withAnimation(.easeOut(duration: 0.2)) {
            UsageManager.shared.selectedProviderId = nil
            UsageManager.shared.isSettingsPopoverOpen = false
        }
    }
    
    private func updateVisibility() {
        if UsageManager.shared.isHudVisible {
            showWindow()
        } else {
            hideWindow()
        }
    }
    
    private func createPanels() {
        let panel = FloatingOverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        
        let hostingView = PassthroughHostingView(rootView: ExpandedShelfView())
        hostingView.translatesAutoresizingMaskIntoConstraints = true
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        self.overlayPanel = panel
    }
    
    private var calculatedDockHeight: CGFloat {
        let count = CGFloat(UsageManager.shared.providers.filter { $0.isEnabled }.count + 1)
        let safeCount = max(1, count)
        return 48.0 + (safeCount * 64.0) + (max(0, safeCount - 1) * 16.0) + 48.0
    }
    
    public func repositionPanels() {
        if overlayPanel == nil {
            createPanels()
        }
        guard let panel = overlayPanel,
              let screen = panel.screen ?? NSScreen.main ?? NSScreen.screens.first else { return }
        
        let manager = UsageManager.shared
        guard manager.isHudVisible else {
            panel.orderOut(nil)
            return
        }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let vOffset = CGFloat(manager.verticalOffset)
        let dockH = calculatedDockHeight
        let totalW: CGFloat = 430
        let totalH: CGFloat = max(dockH, 360)
        
        var frame = NSRect.zero
        
        switch manager.position {
        case .leftEdge:
            let x = screenFrame.minX
            
            let baseY: CGFloat
            switch manager.edgeAlignment {
            case .top:
                baseY = visibleFrame.maxY - dockH - 30
            case .center:
                baseY = visibleFrame.midY - (dockH / 2)
            case .bottom:
                baseY = visibleFrame.minY + 30
            }
            
            let y = max(visibleFrame.minY, min(visibleFrame.maxY - dockH, baseY + vOffset))
            let finalY = y + dockH - totalH
            let safeFinalY = max(visibleFrame.minY, min(visibleFrame.maxY - totalH, finalY))
            frame = NSRect(x: x, y: safeFinalY, width: totalW, height: totalH)
            
        case .rightEdge:
            let x = screenFrame.maxX - totalW
            
            let baseY: CGFloat
            switch manager.edgeAlignment {
            case .top:
                baseY = visibleFrame.maxY - dockH - 30
            case .center:
                baseY = visibleFrame.midY - (dockH / 2)
            case .bottom:
                baseY = visibleFrame.minY + 30
            }
            
            let y = max(visibleFrame.minY, min(visibleFrame.maxY - dockH, baseY + vOffset))
            let finalY = y + dockH - totalH
            let safeFinalY = max(visibleFrame.minY, min(visibleFrame.maxY - totalH, finalY))
            frame = NSRect(x: x, y: safeFinalY, width: totalW, height: totalH)
            
        case .topNotch:
            let notchW: CGFloat = 460
            let notchH: CGFloat = 450
            let x = screenFrame.midX - (notchW / 2)
            let y = screenFrame.maxY - notchH
            frame = NSRect(x: x, y: y, width: notchW, height: notchH)
        }
        
        panel.setFrame(frame, display: true, animate: false)
        if manager.isHudVisible && !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }
}
