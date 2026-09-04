//
//  UsageGaugeView.swift
//  Usage Notch
//

import SwiftUI

public struct UsageGaugeView: View {
    public var usage: ProviderUsage
    public var isSelected: Bool
    public var onTap: () -> Void
    
    @State private var isHovering: Bool = false
    
    // Dynamic ring color based on percentage or provider theme
    private var ringColor: Color {
        let pct = usage.primaryUsedPercent
        if pct >= 85 {
            return Color(red: 0.98, green: 0.32, blue: 0.28) // Urgent red/coral
        } else if pct >= 65 {
            return Color(red: 0.96, green: 0.52, blue: 0.22) // Warning orange (as in Claude 73%)
        } else if pct >= 40 {
            return Color(red: 0.95, green: 0.82, blue: 0.24) // Yellow/gold (as in 52%)
        } else {
            return Color(red: 0.24, green: 0.86, blue: 0.56) // Healthy green (as in 21%)
        }
    }
    
    public var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                ZStack {
                    // Background track ring
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 3.5)
                        .frame(width: 44, height: 44)
                    
                    // Active progress ring
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(1.0, max(0.0, usage.primaryUsedPercent / 100.0))))
                        .stroke(
                            ringColor,
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 44, height: 44)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: usage.primaryUsedPercent)
                    
                    // Inner disc
                    Circle()
                        .fill(Color.black.opacity(0.85))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(isSelected ? 0.3 : 0.08), lineWidth: 1)
                        )
                    
                    // Brand Icon
                    ProviderBrandIcon(
                        provider: usage.id,
                        size: 19,
                        color: .white
                    )
                }
                .shadow(color: ringColor.opacity(isSelected || isHovering ? 0.45 : 0.15), radius: 6, x: 0, y: 0)
                
                // Percentage text label below
                Text("\(Int(usage.primaryUsedPercent))%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.85))
            }
            .scaleEffect(isHovering || isSelected ? 1.06 : 1.0)
            .animation(.easeInOut(duration: 0.18), value: isHovering)
            .animation(.easeInOut(duration: 0.18), value: isSelected)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover in
            isHovering = hover
        }
    }
}
