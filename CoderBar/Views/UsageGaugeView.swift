//
//  UsageGaugeView.swift
//  Usage Notch
//

import SwiftUI

public struct UsageGaugeView: View {
    public var usage: ProviderUsage
    public var isSelected: Bool
    public var onTap: () -> Void
    public var onHoverChanged: ((Bool) -> Void)? = nil
    
    @State private var isHovering: Bool = false
    
    private var isConfiguredOrLive: Bool {
        usage.hasLiveMetrics || !usage.apiKeyOrToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var displayPercent: Double {
        usage.primaryRemainingPercent
    }
    
    private var ringColor: Color {
        if !isConfiguredOrLive {
            return Color.white.opacity(0.18)
        }
        let pct = displayPercent
        if pct <= 15 {
            return Color(red: 0.98, green: 0.32, blue: 0.28) // Urgent red when almost depleted
        } else if pct <= 35 {
            return Color(red: 0.96, green: 0.65, blue: 0.22) // Warning amber
        } else {
            return Color(red: 0.05, green: 0.90, blue: 0.48) // Electric emerald green
        }
    }
    
    public var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    // Background track ring
                    Circle()
                        .stroke(Color.white.opacity(0.10), lineWidth: 3.5)
                        .frame(width: 44, height: 44)
                    
                    // Active progress ring (Remaining quota)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(isConfiguredOrLive ? min(1.0, max(0.0, displayPercent / 100.0)) : 0.0))
                        .stroke(
                            ringColor,
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 44, height: 44)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: displayPercent)
                    
                    // Inner dark disc (pure dark glass with gradient, no teal)
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
                                .stroke(Color.white.opacity(isSelected ? 0.30 : 0.09), lineWidth: 1)
                        )
                    
                    // Provider Brand Icon
                    ProviderBrandIcon(
                        provider: usage.id,
                        size: 19,
                        color: isConfiguredOrLive ? .white : Color.white.opacity(0.55)
                    )
                }
                .shadow(color: ringColor.opacity(isSelected || isHovering ? 0.4 : 0.1), radius: 5, x: 0, y: 0)
                
                // Bold percentage label below ring
                Text(isConfiguredOrLive ? "\(Int(displayPercent))%" : "--")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected || isHovering ? .white : (isConfiguredOrLive ? Color.white.opacity(0.92) : Color.white.opacity(0.40)))
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
