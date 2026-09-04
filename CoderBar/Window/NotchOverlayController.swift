//
//  NotchOverlayController.swift
//  Usage Notch
//

import Cocoa
import SwiftUI
import Combine

final class FloatingOverlayPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}

@MainActor
public final class NotchOverlayController: NSObject {
    public static let shared = NotchOverlayController()
    
    private var bolitaPanel: FloatingOverlayPanel?
    private var shelfPanel: FloatingOverlayPanel?
    
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
    
    // Auto-dismiss the expanded shelf when clicking in Chrome or outside
    private func setupGlobalClickMonitor() {
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor [weak self] in
                guard let self = self,
                      let shelf = self.shelfPanel,
                      shelf.isVisible else { return }
                
                let clickLocation = NSEvent.mouseLocation
                if !shelf.frame.contains(clickLocation) {
                    self.collapse()
                }
            }
        }
    }
    
    public func showWindow() {
        if bolitaPanel == nil || shelfPanel == nil {
            createPanels()
        }
        repositionPanels()
        
        if UsageManager.shared.isExpanded {
            bolitaPanel?.orderOut(nil)
            shelfPanel?.orderFrontRegardless()
        } else {
            shelfPanel?.orderOut(nil)
            bolitaPanel?.orderFrontRegardless()
        }
    }
    
    public func hideWindow() {
        bolitaPanel?.orderOut(nil)
        shelfPanel?.orderOut(nil)
    }
    
    public func expand() {
        UsageManager.shared.isExpanded = true
        bolitaPanel?.orderOut(nil)
        shelfPanel?.orderFrontRegardless()
    }
    
    public func collapse() {
        UsageManager.shared.isExpanded = false
        UsageManager.shared.selectedProviderId = nil
        shelfPanel?.orderOut(nil)
        if UsageManager.shared.isHudVisible {
            bolitaPanel?.orderFrontRegardless()
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
        // 1. Bolita Panel (Fixed micro size: 48x68, Chrome is 100% free)
        let bPanel = FloatingOverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 48, height: 68),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configurePanelProperties(bPanel)
        let bHosting = NSHostingView(rootView: CollapsedBubbleView())
        bHosting.translatesAutoresizingMaskIntoConstraints = true
        bHosting.autoresizingMask = [.width, .height]
        bPanel.contentView = bHosting
        self.bolitaPanel = bPanel
        
        // 2. Shelf Panel (Fixed size: 360x440)
        let sPanel = FloatingOverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 440),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configurePanelProperties(sPanel)
        let sHosting = NSHostingView(rootView: ExpandedShelfView())
        sHosting.translatesAutoresizingMaskIntoConstraints = true
        sHosting.autoresizingMask = [.width, .height]
        sPanel.contentView = sHosting
        self.shelfPanel = sPanel
    }
    
    private func configurePanelProperties(_ panel: NSPanel) {
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
    }
    
    public func repositionPanels() {
        guard let bPanel = bolitaPanel,
              let sPanel = shelfPanel,
              let screen = NSScreen.main else { return }
        
        let manager = UsageManager.shared
        guard manager.isHudVisible else {
            bPanel.orderOut(nil)
            sPanel.orderOut(nil)
            return
        }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let vOffset = CGFloat(manager.verticalOffset)
        
        var bFrame = NSRect.zero
        var sFrame = NSRect.zero
        
        switch manager.position {
        case .rightEdge:
            // Bolita: 48x68, pinned to screen.maxX
            let bWidth: CGFloat = 48
            let bHeight: CGFloat = 68
            let bX = screenFrame.maxX - bWidth
            
            let sWidth: CGFloat = 360
            let sHeight: CGFloat = 440
            let sX = screenFrame.maxX - sWidth
            
            let baseY: CGFloat
            switch manager.edgeAlignment {
            case .top:
                baseY = visibleFrame.maxY - bHeight - 8
            case .center:
                baseY = visibleFrame.midY - (bHeight / 2)
            case .bottom:
                baseY = visibleFrame.minY + 24
            }
            
            let bY = max(visibleFrame.minY, min(visibleFrame.maxY - bHeight, baseY + vOffset))
            // The shelf's top edge aligns with the bolita's top edge
            let sY = bY + bHeight - sHeight
            
            bFrame = NSRect(x: bX, y: bY, width: bWidth, height: bHeight)
            sFrame = NSRect(x: sX, y: sY, width: sWidth, height: sHeight)
            
        case .leftEdge:
            let bWidth: CGFloat = 48
            let bHeight: CGFloat = 68
            let bX = screenFrame.minX
            
            let sWidth: CGFloat = 360
            let sHeight: CGFloat = 440
            let sX = screenFrame.minX
            
            let baseY: CGFloat
            switch manager.edgeAlignment {
            case .top:
                baseY = visibleFrame.maxY - bHeight - 8
            case .center:
                baseY = visibleFrame.midY - (bHeight / 2)
            case .bottom:
                baseY = visibleFrame.minY + 24
            }
            
            let bY = max(visibleFrame.minY, min(visibleFrame.maxY - bHeight, baseY + vOffset))
            let sY = bY + bHeight - sHeight
            
            bFrame = NSRect(x: bX, y: bY, width: bWidth, height: bHeight)
            sFrame = NSRect(x: sX, y: sY, width: sWidth, height: sHeight)
            
        case .topNotch:
            let bWidth: CGFloat = 76
            let bHeight: CGFloat = 42
            let bX = screenFrame.midX - (bWidth / 2)
            let bY = screenFrame.maxY - bHeight
            
            let sWidth: CGFloat = 460
            let sHeight: CGFloat = 320
            let sX = screenFrame.midX - (sWidth / 2)
            let sY = screenFrame.maxY - sHeight
            
            bFrame = NSRect(x: bX, y: bY, width: bWidth, height: bHeight)
            sFrame = NSRect(x: sX, y: sY, width: sWidth, height: sHeight)
        }
        
        DispatchQueue.main.async {
            bPanel.setFrame(bFrame, display: false)
            sPanel.setFrame(sFrame, display: false)
        }
    }
}
