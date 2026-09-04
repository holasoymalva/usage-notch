//
//  ExpandedShelfView.swift
//  Usage Notch
//

import SwiftUI

public struct ExpandedShelfView: View {
    @ObservedObject var usageManager = UsageManager.shared
    
    private var activeProviders: [ProviderUsage] {
        usageManager.providers.filter { $0.isEnabled }
    }
    
    private var currentPopoverUsage: ProviderUsage? {
        if let id = usageManager.selectedProviderId {
            return usageManager.providers.first(where: { $0.id == id })
        }
        return nil
    }
    
    public var body: some View {
        Group {
            switch usageManager.position {
            case .rightEdge:
                rightEdgeLayout
            case .leftEdge:
                leftEdgeLayout
            case .topNotch:
                topNotchLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Right Edge Layout
    private var rightEdgeLayout: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
            
            // Popover Card
            if let usage = currentPopoverUsage {
                UsagePopoverView(
                    usageManager: usageManager,
                    usage: usage,
                    onClose: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            usageManager.selectedProviderId = nil
                        }
                    }
                )
                .padding(.trailing, 72)
                .padding(.top, 10)
            }
            
            // Vertical Shelf Flap
            ZStack(alignment: .trailing) {
                NotchBezelShape(position: .rightEdge, filletRadius: 20, cornerRadius: 24)
                    .fill(Color.black)
                    .frame(width: 64)
                    .shadow(color: Color.black.opacity(0.55), radius: 12, x: -3, y: 0)
                
                VStack(spacing: 14) {
                    // Close button
                    Button(action: {
                        NotchOverlayController.shared.collapse()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.4))
                            .padding(.top, 12)
                            .frame(width: 30, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help("Cerrar")
                    
                    // AI Providers
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
                            }
                        )
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.12))
                        .frame(width: 28)
                    
                    // Settings gear
                    Button(action: {
                        SettingsWindowController.shared.showSettings()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.5))
                            .frame(width: 34, height: 28)
                    }
                    .buttonStyle(.plain)
                    .help("Preferencias")
                    .padding(.bottom, 14)
                }
                .frame(width: 64)
            }
            .frame(width: 64)
        }
        .frame(width: 360, height: 440, alignment: .topTrailing)
    }
    
    // MARK: - Left Edge Layout
    private var leftEdgeLayout: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            
            ZStack(alignment: .leading) {
                NotchBezelShape(position: .leftEdge, filletRadius: 20, cornerRadius: 24)
                    .fill(Color.black)
                    .frame(width: 64)
                    .shadow(color: Color.black.opacity(0.55), radius: 12, x: 3, y: 0)
                
                VStack(spacing: 14) {
                    Button(action: {
                        NotchOverlayController.shared.collapse()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.4))
                            .padding(.top, 12)
                            .frame(width: 30, height: 20)
                    }
                    .buttonStyle(.plain)
                    
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
                            }
                        )
                    }
                    
                    Divider().background(Color.white.opacity(0.12)).frame(width: 28)
                    
                    Button(action: {
                        SettingsWindowController.shared.showSettings()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.5))
                            .frame(width: 34, height: 28)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 14)
                }
                .frame(width: 64)
            }
            .frame(width: 64)
            
            if let usage = currentPopoverUsage {
                UsagePopoverView(
                    usageManager: usageManager,
                    usage: usage,
                    onClose: {
                        withAnimation { usageManager.selectedProviderId = nil }
                    }
                )
                .padding(.leading, 72)
                .padding(.top, 10)
            }
        }
        .frame(width: 360, height: 440, alignment: .topLeading)
    }
    
    // MARK: - Top Notch Layout
    private var topNotchLayout: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                NotchBezelShape(position: .topNotch, filletRadius: 16, cornerRadius: 20)
                    .fill(Color.black)
                    .frame(height: 60)
                    .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 3)
                
                HStack(spacing: 16) {
                    Button(action: {
                        NotchOverlayController.shared.collapse()
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    
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
                            }
                        )
                    }
                    
                    Divider().background(Color.white.opacity(0.12)).frame(height: 24)
                    
                    Button(action: {
                        SettingsWindowController.shared.showSettings()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
            }
            .frame(height: 60)
            
            if let usage = currentPopoverUsage {
                UsagePopoverView(
                    usageManager: usageManager,
                    usage: usage,
                    onClose: {
                        withAnimation { usageManager.selectedProviderId = nil }
                    }
                )
                .padding(.top, 8)
            }
            
            Spacer(minLength: 0)
        }
        .frame(width: 460, height: 320, alignment: .top)
    }
}
