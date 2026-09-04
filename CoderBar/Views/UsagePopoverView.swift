//
//  UsagePopoverView.swift
//  Usage Notch
//

import SwiftUI

public struct UsagePopoverView: View {
    @ObservedObject var usageManager: UsageManager
    public var usage: ProviderUsage
    public var onClose: () -> Void
    
    @State private var isAdjusting: Bool = false
    
    private var primaryBarGradient: LinearGradient {
        let pct = usage.primaryUsedPercent
        if pct >= 80 {
            return LinearGradient(
                colors: [Color(red: 0.98, green: 0.45, blue: 0.22), Color(red: 0.96, green: 0.25, blue: 0.25)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if pct >= 50 {
            return LinearGradient(
                colors: [Color(red: 0.98, green: 0.58, blue: 0.24), Color(red: 0.95, green: 0.40, blue: 0.20)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [Color(red: 0.22, green: 0.82, blue: 0.52), Color(red: 0.18, green: 0.72, blue: 0.45)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Icon + Name + Close
            HStack(spacing: 9) {
                ProviderBrandIcon(
                    provider: usage.id,
                    size: 20,
                    color: .white
                )
                
                Text("\(usage.id.displayName) Usage")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { isAdjusting.toggle() }) {
                    Image(systemName: isAdjusting ? "slider.horizontal.3" : "slider.horizontal.2")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isAdjusting ? usage.id.defaultAccentColor : Color.white.opacity(0.45))
                }
                .buttonStyle(.plain)
                .help("Ajustar consumo manualmente")
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            
            // Metric 1: Current session
            VStack(alignment: .leading, spacing: 6) {
                Text(usage.primaryLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.65))
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 7)
                        
                        Capsule()
                            .fill(primaryBarGradient)
                            .frame(width: max(7, geo.size.width * CGFloat(min(100.0, usage.primaryUsedPercent) / 100.0)), height: 7)
                            .shadow(color: Color.orange.opacity(0.35), radius: 4, x: 0, y: 0)
                    }
                }
                .frame(height: 7)
                
                HStack {
                    Text("\(Int(usage.primaryUsedPercent))% Used")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(usage.primaryTimeRemainingString)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.55))
                }
            }
            
            // Metric 2: Secondary (All models / Monthly)
            VStack(alignment: .leading, spacing: 6) {
                Text(usage.secondaryLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.65))
                
                // Progress Bar (Greenish)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 7)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.20, green: 0.85, blue: 0.55), Color(red: 0.16, green: 0.70, blue: 0.45)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(7, geo.size.width * CGFloat(min(100.0, usage.secondaryUsedPercent) / 100.0)), height: 7)
                    }
                }
                .frame(height: 7)
                
                HStack {
                    Text("\(Int(usage.secondaryUsedPercent))% Used")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(usage.secondaryResetString)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.55))
                }
            }
            
            // Quick Adjust Panel (if toggled)
            if isAdjusting {
                Divider().background(Color.white.opacity(0.15))
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Simular/Ajustar uso:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.6))
                        Spacer()
                        Text("\(Int(usage.primaryUsedPercent))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(usage.id.defaultAccentColor)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { usage.primaryUsedPercent },
                            set: { usageManager.updateUsage(for: usage.id, primaryPercent: $0) }
                        ),
                        in: 0...100
                    )
                    .tint(usage.id.defaultAccentColor)
                    
                    HStack(spacing: 8) {
                        Button("+5%") {
                            usageManager.adjustUsage(for: usage.id, delta: 5.0)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("+15%") {
                            usageManager.adjustUsage(for: usage.id, delta: 15.0)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        Button("Reiniciar sesión") {
                            usageManager.resetSession(for: usage.id)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.white.opacity(0.18))
                        .controlSize(.small)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.09).opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 8)
        )
    }
}
