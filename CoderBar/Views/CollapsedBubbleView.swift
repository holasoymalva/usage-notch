//
//  CollapsedBubbleView.swift
//  Usage Notch
//

import SwiftUI

public struct CollapsedBubbleView: View {
    @ObservedObject var usageManager = UsageManager.shared
    
    public var body: some View {
        Button(action: {
            NotchOverlayController.shared.expand()
        }) {
            Group {
                switch usageManager.position {
                case .rightEdge:
                    rightBubble
                case .leftEdge:
                    leftBubble
                case .topNotch:
                    topBubble
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var rightBubble: some View {
        ZStack(alignment: .trailing) {
            NotchBezelShape(position: .rightEdge, filletRadius: 14, cornerRadius: 18)
                .fill(Color.black)
                .frame(width: 48, height: 68)
                .shadow(color: Color.black.opacity(0.4), radius: 6, x: -2, y: 0)
            
            let primary = usageManager.primaryUsage
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 3.0)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(1.0, primary.primaryUsedPercent / 100.0)))
                    .stroke(
                        ringColor(for: primary.primaryUsedPercent),
                        style: StrokeStyle(lineWidth: 3.0, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 32, height: 32)
                
                Circle()
                    .fill(Color.black.opacity(0.9))
                    .frame(width: 24, height: 24)
                
                ProviderBrandIcon(provider: primary.id, size: 13, color: .white)
            }
            .padding(.trailing, 7)
        }
        .frame(width: 48, height: 68)
    }
    
    private var leftBubble: some View {
        ZStack(alignment: .leading) {
            NotchBezelShape(position: .leftEdge, filletRadius: 14, cornerRadius: 18)
                .fill(Color.black)
                .frame(width: 48, height: 68)
                .shadow(color: Color.black.opacity(0.4), radius: 6, x: 2, y: 0)
            
            let primary = usageManager.primaryUsage
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 3.0)
                    .frame(width: 32, height: 32)
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(1.0, primary.primaryUsedPercent / 100.0)))
                    .stroke(ringColor(for: primary.primaryUsedPercent), style: StrokeStyle(lineWidth: 3.0, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 32, height: 32)
                Circle().fill(Color.black.opacity(0.9)).frame(width: 24, height: 24)
                ProviderBrandIcon(provider: primary.id, size: 13, color: .white)
            }
            .padding(.leading, 7)
        }
        .frame(width: 48, height: 68)
    }
    
    private var topBubble: some View {
        ZStack(alignment: .top) {
            NotchBezelShape(position: .topNotch, filletRadius: 12, cornerRadius: 16)
                .fill(Color.black)
                .frame(width: 76, height: 42)
                .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)
            
            let primary = usageManager.primaryUsage
            HStack(spacing: 6) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.12), lineWidth: 2.5).frame(width: 22, height: 22)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(1.0, primary.primaryUsedPercent / 100.0)))
                        .stroke(ringColor(for: primary.primaryUsedPercent), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 22, height: 22)
                    ProviderBrandIcon(provider: primary.id, size: 10, color: .white)
                }
                Text("\(Int(primary.primaryUsedPercent))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.top, 5)
        }
        .frame(width: 76, height: 42)
    }
    
    private func ringColor(for pct: Double) -> Color {
        if pct >= 85 {
            return Color(red: 0.98, green: 0.32, blue: 0.28)
        } else if pct >= 65 {
            return Color(red: 0.96, green: 0.52, blue: 0.22)
        } else if pct >= 40 {
            return Color(red: 0.95, green: 0.82, blue: 0.24)
        } else {
            return Color(red: 0.24, green: 0.86, blue: 0.56)
        }
    }
}
