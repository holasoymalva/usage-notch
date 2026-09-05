//
//  QuickSettingsView.swift
//  Usage Notch
//

import SwiftUI

// MARK: - Settings Dock Button
public struct SettingsDockButton: View {
    public var isSelected: Bool
    public var onTap: () -> Void
    public var onHoverChanged: ((Bool) -> Void)? = nil
    
    @State private var isHovering: Bool = false
    
    public init(
        isSelected: Bool,
        onTap: @escaping () -> Void,
        onHoverChanged: ((Bool) -> Void)? = nil
    ) {
        self.isSelected = isSelected
        self.onTap = onTap
        self.onHoverChanged = onHoverChanged
    }
    
    public var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    // Track circle
                    Circle()
                        .stroke(Color.white.opacity(0.10), lineWidth: 3.5)
                        .frame(width: 44, height: 44)
                    
                    // Specular glowing accent ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: isSelected || isHovering ? Color(red: 0.05, green: 0.90, blue: 0.48) : Color.white.opacity(0.35), location: 0.0),
                                    .init(color: isSelected || isHovering ? Color.cyan : Color.white.opacity(0.12), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3.5
                        )
                        .frame(width: 44, height: 44)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isHovering)
                    
                    // Inner dark glass disc
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(white: 0.13).opacity(0.92),
                                    Color(white: 0.04).opacity(0.98)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 35, height: 35)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(isSelected ? 0.35 : 0.09), lineWidth: 1)
                        )
                    
                    // Gear Icon that rotates subtly on hover
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isHovering ? 45 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isHovering)
                }
                .shadow(color: (isSelected || isHovering ? Color(red: 0.05, green: 0.90, blue: 0.48) : Color.white).opacity(isSelected || isHovering ? 0.4 : 0.08), radius: 5, x: 0, y: 0)
                
                // Label below ring
                Text("Ajustes")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected || isHovering ? .white : Color.white.opacity(0.85))
            }
            .scaleEffect(isHovering || isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.16), value: isHovering)
            .animation(.easeInOut(duration: 0.16), value: isSelected)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover in
            isHovering = hover
            onHoverChanged?(hover)
        }
    }
}

// MARK: - Quick Settings Popover View
public struct QuickSettingsPopoverView: View {
    @ObservedObject var usageManager: UsageManager
    public var arrowY: CGFloat = 40.0
    public var onClose: () -> Void = {}
    
    public init(
        usageManager: UsageManager,
        arrowY: CGFloat = 40.0,
        onClose: @escaping () -> Void = {}
    ) {
        self.usageManager = usageManager
        self.arrowY = arrowY
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.05, green: 0.90, blue: 0.48))
                
                Text("Ajustes del Dock")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
            
            // Section 1: Dirección y Posición
            VStack(alignment: .leading, spacing: 5) {
                Text("DIRECCIÓN / BORDE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.50))
                
                HStack(spacing: 6) {
                    directionOptionButton(
                        title: "Izquierda",
                        icon: "arrow.left.to.line.compact",
                        pos: .leftEdge
                    )
                    directionOptionButton(
                        title: "Derecha",
                        icon: "arrow.right.to.line.compact",
                        pos: .rightEdge
                    )
                    directionOptionButton(
                        title: "Notch",
                        icon: "macbook.and.ipad",
                        pos: .topNotch
                    )
                }
            }
            
            // Section 2: Alineación Vertical
            VStack(alignment: .leading, spacing: 5) {
                Text("ALINEACIÓN VERTICAL")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.50))
                
                HStack(spacing: 6) {
                    alignmentOptionButton(title: "Arriba", align: .top)
                    alignmentOptionButton(title: "Centro", align: .center)
                    alignmentOptionButton(title: "Abajo", align: .bottom)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Section 3: Abrir Preferencias Completas
            Button(action: {
                onClose()
                SettingsWindowController.shared.showSettings()
            }) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: "gearshape.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Abrir Preferencias...")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(.white)
                        Text("37 Proveedores, API Keys y Cuotas")
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.60))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            // Section 4: Acciones rápidas
            HStack(spacing: 8) {
                Button(action: {
                    Task {
                        await APIUsageService.shared.syncAllServices()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .medium))
                        Text("Sincronizar")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Color.white.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    usageManager.isHudVisible = false
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 11, weight: .medium))
                        Text("Ocultar")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Color.white.opacity(0.65))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, usageManager.position != .rightEdge ? 22 : 16)
        .padding(.trailing, usageManager.position == .rightEdge ? 22 : 16)
        .padding(.vertical, 13)
        .frame(width: 315)
        .background(
            ZStack {
                // 1. Native macOS frosted blur
                PopoverBezelShape(
                    arrowPosition: usageManager.position,
                    arrowY: arrowY,
                    arrowWidth: 8,
                    arrowHeight: 14,
                    cornerRadius: 19
                )
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                
                // 2. Translucent deep black glass
                PopoverBezelShape(
                    arrowPosition: usageManager.position,
                    arrowY: arrowY,
                    arrowWidth: 8,
                    arrowHeight: 14,
                    cornerRadius: 19
                )
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(white: 0.15).opacity(0.85), location: 0.0),
                            .init(color: Color(white: 0.07).opacity(0.90), location: 0.5),
                            .init(color: Color(white: 0.03).opacity(0.95), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // 3. Subtle specular glass reflection
                PopoverBezelShape(
                    arrowPosition: usageManager.position,
                    arrowY: arrowY,
                    arrowWidth: 8,
                    arrowHeight: 14,
                    cornerRadius: 19
                )
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            }
            .overlay(
                PopoverBezelShape(
                    arrowPosition: usageManager.position,
                    arrowY: arrowY,
                    arrowWidth: 8,
                    arrowHeight: 14,
                    cornerRadius: 19
                )
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.35), location: 0.0),
                            .init(color: Color.white.opacity(0.16), location: 0.4),
                            .init(color: Color.white.opacity(0.08), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
            .shadow(color: Color.black.opacity(0.58), radius: 24, x: 0, y: 10)
        )
    }
    
    // MARK: - Subcomponents
    private func directionOptionButton(title: String, icon: String, pos: NotchPosition) -> some View {
        let isSelected = usageManager.position == pos
        return Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                usageManager.position = pos
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? Color(red: 0.05, green: 0.90, blue: 0.48) : Color.white.opacity(0.70))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 0.05, green: 0.90, blue: 0.48).opacity(0.15) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(red: 0.05, green: 0.90, blue: 0.48).opacity(0.50) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func alignmentOptionButton(title: String, align: EdgeAlignment) -> some View {
        let isSelected = usageManager.edgeAlignment == align
        return Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                usageManager.edgeAlignment = align
            }
        }) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.65))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.white.opacity(0.35) : Color.white.opacity(0.06), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
