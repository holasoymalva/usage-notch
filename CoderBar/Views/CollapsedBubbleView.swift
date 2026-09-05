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
            ZStack {
                NotchBezelShape(position: .rightEdge, flareHeight: 18, flareWidth: 16, cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                NotchBezelShape(position: .rightEdge, flareHeight: 18, flareWidth: 16, cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(white: 0.15).opacity(0.82), location: 0.0),
                                .init(color: Color(white: 0.04).opacity(0.92), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                NotchBezelShape(position: .rightEdge, flareHeight: 18, flareWidth: 16, cornerRadius: 16, isOutlineOnly: true)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            )
            .frame(width: 48, height: 68)
            .shadow(color: Color.black.opacity(0.4), radius: 6, x: -2, y: 0)
            
            let primary = usageManager.primaryUsage
            let isConfigured = primary.hasLiveMetrics || !primary.apiKeyOrToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let rem = primary.primaryRemainingPercent
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 3.0)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(isConfigured ? min(1.0, max(0.0, rem / 100.0)) : 0.0))
                    .stroke(
                        isConfigured ? ringColor(for: rem) : Color.white.opacity(0.18),
                        style: StrokeStyle(lineWidth: 3.0, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 32, height: 32)
                
                Circle()
                    .fill(Color(white: 0.08).opacity(0.95))
                    .frame(width: 24, height: 24)
                
                ProviderBrandIcon(provider: primary.id, size: 13, color: isConfigured ? .white : Color.white.opacity(0.55))
            }
            .padding(.trailing, 7)
        }
        .frame(width: 48, height: 68)
    }
    
    private var leftBubble: some View {
        ZStack(alignment: .leading) {
            ZStack {
                NotchBezelShape(position: .leftEdge, flareHeight: 18, flareWidth: 16, cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                NotchBezelShape(position: .leftEdge, flareHeight: 18, flareWidth: 16, cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(white: 0.15).opacity(0.82), location: 0.0),
                                .init(color: Color(white: 0.04).opacity(0.92), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                NotchBezelShape(position: .leftEdge, flareHeight: 18, flareWidth: 16, cornerRadius: 16, isOutlineOnly: true)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            )
            .frame(width: 48, height: 68)
            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 2, y: 0)
            
            let primary = usageManager.primaryUsage
            let isConfigured = primary.hasLiveMetrics || !primary.apiKeyOrToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let rem = primary.primaryRemainingPercent
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 3.0)
                    .frame(width: 32, height: 32)
                Circle()
                    .trim(from: 0.0, to: CGFloat(isConfigured ? min(1.0, max(0.0, rem / 100.0)) : 0.0))
                    .stroke(isConfigured ? ringColor(for: rem) : Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 3.0, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 32, height: 32)
                Circle()
                    .fill(Color(white: 0.08).opacity(0.95))
                    .frame(width: 24, height: 24)
                ProviderBrandIcon(provider: primary.id, size: 13, color: isConfigured ? .white : Color.white.opacity(0.55))
            }
            .padding(.leading, 7)
        }
        .frame(width: 48, height: 68)
    }
    
    private var topBubble: some View {
        ZStack(alignment: .top) {
            ZStack {
                NotchBezelShape(position: .topNotch, flareHeight: 14, flareWidth: 14, cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                NotchBezelShape(position: .topNotch, flareHeight: 14, flareWidth: 14, cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(white: 0.15).opacity(0.82), location: 0.0),
                                .init(color: Color(white: 0.04).opacity(0.92), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                NotchBezelShape(position: .topNotch, flareHeight: 14, flareWidth: 14, cornerRadius: 14, isOutlineOnly: true)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            )
            .frame(width: 76, height: 42)
            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)
            
            let primary = usageManager.primaryUsage
            let isConfigured = primary.hasLiveMetrics || !primary.apiKeyOrToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let rem = primary.primaryRemainingPercent
            HStack(spacing: 6) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.10), lineWidth: 2.5).frame(width: 22, height: 22)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(isConfigured ? min(1.0, max(0.0, rem / 100.0)) : 0.0))
                        .stroke(isConfigured ? ringColor(for: rem) : Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 22, height: 22)
                    ProviderBrandIcon(provider: primary.id, size: 10, color: isConfigured ? .white : Color.white.opacity(0.55))
                }
                Text(isConfigured ? "\(Int(rem))%" : "--")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(isConfigured ? .white : Color.white.opacity(0.5))
            }
            .padding(.top, 5)
        }
        .frame(width: 76, height: 42)
    }
    
    private func ringColor(for rem: Double) -> Color {
        if rem <= 15 {
            return Color(red: 0.98, green: 0.32, blue: 0.28)
        } else if rem <= 35 {
            return Color(red: 0.96, green: 0.65, blue: 0.22)
        } else {
            return Color(red: 0.05, green: 0.90, blue: 0.48)
        }
    }
}
