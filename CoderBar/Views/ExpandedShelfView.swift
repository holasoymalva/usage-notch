//
//  ExpandedShelfView.swift
//  Usage Notch
//

import SwiftUI

public struct ExpandedShelfView: View {
    @ObservedObject var usageManager = UsageManager.shared
    @State private var dismissTask: Task<Void, Never>? = nil
    
    private var activeProviders: [ProviderUsage] {
        let list = usageManager.providers.filter { $0.isEnabled }
        return list.isEmpty ? usageManager.providers.prefix(3).map { $0 } : list
    }
    
    private var currentPopoverUsage: ProviderUsage? {
        if let id = usageManager.selectedProviderId {
            return activeProviders.first(where: { $0.id == id }) ?? activeProviders.first
        }
        return nil
    }
    
    private var activeIndex: Int {
        guard let id = usageManager.selectedProviderId,
              let idx = activeProviders.firstIndex(where: { $0.id == id }) else {
            return 0
        }
        return idx
    }
    
    private var dockHeight: CGFloat {
        let count = CGFloat(activeProviders.count + 1) // Active providers + Ajustes button
        return 48.0 + (count * 64.0) + (max(0, count - 1) * 16.0) + 48.0
    }
    
    public var body: some View {
        Group {
            switch usageManager.position {
            case .leftEdge:
                leftEdgeLayout
            case .rightEdge:
                rightEdgeLayout
            case .topNotch:
                topNotchLayout
            }
        }
        .onHover { isHovered in
            if !isHovered {
                dismissTask?.cancel()
                dismissTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        usageManager.selectedProviderId = nil
                        usageManager.isSettingsPopoverOpen = false
                    }
                }
            } else {
                dismissTask?.cancel()
            }
        }
    }
    
    // MARK: - Translucent Dark Glass Dock Background
    private func dockGlassBackground(position: NotchPosition) -> some View {
        ZStack {
            // 1. Native macOS frosted glass blur
            NotchBezelShape(position: position, flareHeight: 38, flareWidth: 30, cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            
            // 2. Translucent deep black glass gradient (NO green/teal)
            NotchBezelShape(position: position, flareHeight: 38, flareWidth: 30, cornerRadius: 24)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(white: 0.15).opacity(0.82), location: 0.0),
                            .init(color: Color(white: 0.07).opacity(0.88), location: 0.5),
                            .init(color: Color(white: 0.02).opacity(0.94), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 3. Subtle top specular reflection sheen
            NotchBezelShape(position: position, flareHeight: 38, flareWidth: 30, cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.10), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
        }
        .overlay(
            // 4. Highlight stroke only along the curve exposed to the desktop (not against the physical screen edge!)
            NotchBezelShape(position: position, flareHeight: 38, flareWidth: 30, cornerRadius: 24, isOutlineOnly: true)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.42), location: 0.0),
                            .init(color: Color.white.opacity(0.24), location: 0.20),
                            .init(color: Color.white.opacity(0.12), location: 0.60),
                            .init(color: Color.white.opacity(0.22), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: Color.black.opacity(0.52), radius: 18, x: position == .leftEdge ? 3 : -3, y: 0)
    }
    
    // MARK: - Left Edge Layout (Mockup Primary)
    private var leftEdgeLayout: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            
            // 1. Sleek Dock Flap on Left Screen Edge
            ZStack(alignment: .leading) {
                dockGlassBackground(position: .leftEdge)
                    .frame(width: 74, height: dockHeight)
                
                VStack(spacing: 16) {
                    ForEach(activeProviders) { item in
                        UsageGaugeView(
                            usage: item,
                            isSelected: usageManager.selectedProviderId == item.id,
                            onTap: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    if usageManager.selectedProviderId == item.id {
                                        usageManager.selectedProviderId = nil
                                    } else {
                                        usageManager.selectedProviderId = item.id
                                    }
                                }
                            },
                            onHoverChanged: { isHovered in
                                if isHovered {
                                    dismissTask?.cancel()
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        usageManager.selectedProviderId = item.id
                                    }
                                }
                            }
                        )
                    }
                    
                    // ⚙️ Settings / Ajustes button as the last option
                    SettingsDockButton(
                        isSelected: usageManager.isSettingsPopoverOpen,
                        onTap: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                usageManager.isSettingsPopoverOpen.toggle()
                            }
                        },
                        onHoverChanged: { isHovered in
                            if isHovered {
                                dismissTask?.cancel()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    usageManager.isSettingsPopoverOpen = true
                                }
                            }
                        }
                    )
                }
                .padding(.vertical, 48)
                .frame(width: 74)
            }
            .frame(width: 74, height: dockHeight, alignment: .leading)
            .contextMenu {
                contextMenuItems
            }
            
            // 2. Contextual Popover Card with Arrow
            if let usage = currentPopoverUsage {
                let gaugeCenterY = 48.0 + CGFloat(activeIndex) * (64.0 + 16.0) + 22.0
                let cardTop = max(8.0, min(dockHeight - 160.0, gaugeCenterY - 45.0))
                let arrowY = max(22.0, gaugeCenterY - cardTop)
                
                UsagePopoverView(
                    usageManager: usageManager,
                    usage: usage,
                    arrowY: arrowY,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            usageManager.selectedProviderId = nil
                        }
                    }
                )
                .offset(x: 70, y: cardTop)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .leading)),
                    removal: .opacity
                ))
            } else if usageManager.isSettingsPopoverOpen {
                let settingsIndex = activeProviders.count
                let gaugeCenterY = 48.0 + CGFloat(settingsIndex) * (64.0 + 16.0) + 22.0
                let cardTop = max(8.0, min(dockHeight - 220.0, gaugeCenterY - 110.0))
                let arrowY = max(22.0, gaugeCenterY - cardTop)
                
                QuickSettingsPopoverView(
                    usageManager: usageManager,
                    arrowY: arrowY,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            usageManager.isSettingsPopoverOpen = false
                        }
                    }
                )
                .offset(x: 70, y: cardTop)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .leading)),
                    removal: .opacity
                ))
            }
        }
        .frame(width: 420, height: max(dockHeight + 60, 420), alignment: .topLeading)
    }
    
    // MARK: - Right Edge Layout
    private var rightEdgeLayout: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
            
            // Popover Card
            if let usage = currentPopoverUsage {
                let gaugeCenterY = 48.0 + CGFloat(activeIndex) * (64.0 + 16.0) + 22.0
                let cardTop = max(8.0, min(dockHeight - 160.0, gaugeCenterY - 45.0))
                let arrowY = max(22.0, gaugeCenterY - cardTop)
                
                UsagePopoverView(
                    usageManager: usageManager,
                    usage: usage,
                    arrowY: arrowY,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            usageManager.selectedProviderId = nil
                        }
                    }
                )
                .offset(x: -70, y: cardTop)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .trailing)),
                    removal: .opacity
                ))
            } else if usageManager.isSettingsPopoverOpen {
                let settingsIndex = activeProviders.count
                let gaugeCenterY = 48.0 + CGFloat(settingsIndex) * (64.0 + 16.0) + 22.0
                let cardTop = max(8.0, min(dockHeight - 220.0, gaugeCenterY - 110.0))
                let arrowY = max(22.0, gaugeCenterY - cardTop)
                
                QuickSettingsPopoverView(
                    usageManager: usageManager,
                    arrowY: arrowY,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            usageManager.isSettingsPopoverOpen = false
                        }
                    }
                )
                .offset(x: -70, y: cardTop)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .trailing)),
                    removal: .opacity
                ))
            }
            
            // Dock Flap on Right Screen Edge
            ZStack(alignment: .trailing) {
                dockGlassBackground(position: .rightEdge)
                    .frame(width: 74, height: dockHeight)
                
                VStack(spacing: 16) {
                    ForEach(activeProviders) { item in
                        UsageGaugeView(
                            usage: item,
                            isSelected: usageManager.selectedProviderId == item.id,
                            onTap: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    if usageManager.selectedProviderId == item.id {
                                        usageManager.selectedProviderId = nil
                                    } else {
                                        usageManager.selectedProviderId = item.id
                                    }
                                }
                            },
                            onHoverChanged: { isHovered in
                                if isHovered {
                                    dismissTask?.cancel()
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        usageManager.selectedProviderId = item.id
                                    }
                                }
                            }
                        )
                    }
                    
                    // ⚙️ Settings / Ajustes button as the last option
                    SettingsDockButton(
                        isSelected: usageManager.isSettingsPopoverOpen,
                        onTap: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                usageManager.isSettingsPopoverOpen.toggle()
                            }
                        },
                        onHoverChanged: { isHovered in
                            if isHovered {
                                dismissTask?.cancel()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    usageManager.isSettingsPopoverOpen = true
                                }
                            }
                        }
                    )
                }
                .padding(.vertical, 48)
                .frame(width: 74)
            }
            .frame(width: 74, height: dockHeight, alignment: .trailing)
            .contextMenu {
                contextMenuItems
            }
        }
        .frame(width: 420, height: max(dockHeight + 60, 420), alignment: .topTrailing)
    }
    
    // MARK: - Top Notch Layout
    private var topNotchLayout: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .top) {
                dockGlassBackground(position: .topNotch)
                    .frame(height: 56)
                
                HStack(spacing: 18) {
                    ForEach(activeProviders) { item in
                        UsageGaugeView(
                            usage: item,
                            isSelected: usageManager.selectedProviderId == item.id,
                            onTap: {
                                withAnimation {
                                    if usageManager.selectedProviderId == item.id {
                                        usageManager.selectedProviderId = nil
                                    } else {
                                        usageManager.selectedProviderId = item.id
                                    }
                                }
                            },
                            onHoverChanged: { isHovered in
                                if isHovered {
                                    withAnimation {
                                        usageManager.selectedProviderId = item.id
                                    }
                                }
                            }
                        )
                    }
                    
                    SettingsDockButton(
                        isSelected: usageManager.isSettingsPopoverOpen,
                        onTap: {
                            withAnimation {
                                usageManager.isSettingsPopoverOpen.toggle()
                            }
                        },
                        onHoverChanged: { isHovered in
                            if isHovered {
                                withAnimation {
                                    usageManager.isSettingsPopoverOpen = true
                                }
                            }
                        }
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
            }
            .frame(height: 56)
            .contextMenu {
                contextMenuItems
            }
            
            if let usage = currentPopoverUsage {
                UsagePopoverView(
                    usageManager: usageManager,
                    usage: usage,
                    arrowY: 20,
                    onClose: {
                        withAnimation { usageManager.selectedProviderId = nil }
                    }
                )
            } else if usageManager.isSettingsPopoverOpen {
                QuickSettingsPopoverView(
                    usageManager: usageManager,
                    arrowY: 20,
                    onClose: {
                        withAnimation { usageManager.isSettingsPopoverOpen = false }
                    }
                )
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Context Menu
    @ViewBuilder
    private var contextMenuItems: some View {
        Button("Sincronizar APIs Ahora") {
            Task {
                await APIUsageService.shared.syncAllServices()
            }
        }
        
        Button("Preferencias...") {
            SettingsWindowController.shared.showSettings()
        }
        
        Divider()
        
        Button("Ocultar CoderBar") {
            usageManager.isHudVisible = false
        }
        
        Button("Salir") {
            NSApplication.shared.terminate(nil)
        }
    }
}
