//
//  UsagePopoverView.swift
//  Usage Notch
//

import SwiftUI

public struct UsagePopoverView: View {
    @ObservedObject var usageManager: UsageManager
    public var usage: ProviderUsage
    public var arrowY: CGFloat = 40.0
    public var onClose: () -> Void = {}
    
    public init(
        usageManager: UsageManager,
        usage: ProviderUsage,
        arrowY: CGFloat = 40.0,
        onClose: @escaping () -> Void = {}
    ) {
        self.usageManager = usageManager
        self.usage = usage
        self.arrowY = arrowY
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Brand Icon + Provider Title + Reset in Xh Ym
            HStack(alignment: .top, spacing: 9) {
                ProviderBrandIcon(
                    provider: usage.id,
                    size: 20,
                    color: .white
                )
                .padding(.top, 1)
                
                Text("\(usage.id.displayName) Usage")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 8)
                
                Text(usage.headerResetString)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.62))
                    .padding(.top, 1)
            }
            
            // Section 1: Primary Metric
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(usage.primaryLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if usage.hasLiveMetrics && usage.maxCount > 0 && usage.unitName != "%" {
                        if usage.unitName == "$" {
                            Text("$\(String(format: "%.2f", usage.currentCount)) / $\(String(format: "%.2f", usage.maxCount))")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(red: 0.05, green: 0.90, blue: 0.48))
                        } else {
                            Text("\(Int(usage.currentCount)) / \(Int(usage.maxCount)) \(usage.unitName)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(red: 0.05, green: 0.90, blue: 0.48))
                        }
                    }
                }
                
                // Thin progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 4.5)
                        
                        let pct = usage.primaryRemainingPercent / 100.0
                        Capsule()
                            .fill(Color(red: 0.05, green: 0.90, blue: 0.48))
                            .frame(width: max(4.5, geo.size.width * CGFloat(min(1.0, max(0.0, pct)))), height: 4.5)
                    }
                }
                .frame(height: 4.5)
                
                HStack {
                    Text("\(Int(usage.primaryRemainingPercent))% Restante")
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.72))
                    
                    Spacer()
                    
                    Text(usage.primaryResetTimeString)
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.55))
                }
            }
            
            // Section 2: Secondary Metric (e.g. Weekly or Tier Allowance)
            if usage.secondaryUsedPercent > 0 || usage.id == .antigravity || usage.id == .cursor || usage.id == .codex {
                VStack(alignment: .leading, spacing: 6) {
                    Text(usage.secondaryLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Thin progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 4.5)
                            
                            let pct = usage.secondaryRemainingPercent / 100.0
                            Capsule()
                                .fill(Color(red: 0.05, green: 0.90, blue: 0.48))
                                .frame(width: max(4.5, geo.size.width * CGFloat(min(1.0, max(0.0, pct)))), height: 4.5)
                        }
                    }
                    .frame(height: 4.5)
                    
                    HStack {
                        Text("\(Int(usage.secondaryRemainingPercent))% Restante")
                            .font(.system(size: 11.5, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.72))
                        
                        Spacer()
                        
                        Text(usage.secondaryResetTimeString)
                            .font(.system(size: 11.5, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.55))
                    }
                }
            }
            
            // Section 3: Token / Model Stats
            if usage.tokensToday != nil || usage.tokensMonth != nil {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Detalles de Consumo")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let today = usage.tokensToday {
                        HStack {
                            Text("Estado")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.72))
                            Spacer()
                            Text(today)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                    
                    if let month = usage.tokensMonth {
                        HStack {
                            Text("Ciclo")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.72))
                            Spacer()
                            Text(month)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Divider().opacity(0.15)
            
            // Footer: Live status & sync action
            HStack(spacing: 8) {
                Text(usage.lastSyncStatus)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.75))
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: {
                    Task {
                        _ = await APIUsageService.shared.testAndSync(providerId: usage.id)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.05, green: 0.90, blue: 0.48))
                }
                .buttonStyle(.plain)
                .help("Sincronizar ahora")
            }
        }
        .padding(.leading, usageManager.position != .rightEdge ? 22 : 16)
        .padding(.trailing, usageManager.position == .rightEdge ? 22 : 16)
        .padding(.vertical, 16)
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
                
                // 2. Translucent deep black glass with subtle gradient
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
                
                // 3. Subtle top specular glass reflection
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
}
