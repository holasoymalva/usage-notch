//
//  BrandIcons.swift
//  Usage Notch
//

import SwiftUI

public struct ClaudeStarburstIcon: View {
    public var size: CGFloat = 20
    public var color: Color = .white
    
    public init(size: CGFloat = 20, color: Color = .white) {
        self.size = size
        self.color = color
    }
    
    public var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Capsule()
                    .fill(color)
                    .frame(width: size * 0.14, height: size * 0.44)
                    .offset(y: -size * 0.22)
                    .rotationEffect(.degrees(Double(i) * 45.0))
            }
            Circle()
                .fill(color)
                .frame(width: size * 0.28, height: size * 0.28)
        }
        .frame(width: size, height: size)
    }
}

public struct OpenAISpiralIcon: View {
    public var size: CGFloat = 20
    public var color: Color = .white
    
    public init(size: CGFloat = 20, color: Color = .white) {
        self.size = size
        self.color = color
    }
    
    public var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                Capsule()
                    .stroke(color, lineWidth: size * 0.1)
                    .frame(width: size * 0.24, height: size * 0.48)
                    .offset(x: size * 0.12, y: -size * 0.1)
                    .rotationEffect(.degrees(Double(i) * 60.0))
            }
        }
        .frame(width: size, height: size)
    }
}

public struct IsometricCubeIcon: View {
    public var size: CGFloat = 20
    public var color: Color = .white
    
    public init(size: CGFloat = 20, color: Color = .white) {
        self.size = size
        self.color = color
    }
    
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cx = w / 2
            let cy = h / 2
            let r = min(w, h) * 0.42
            
            // Top diamond
            var top = Path()
            top.move(to: CGPoint(x: cx, y: cy - r))
            top.addLine(to: CGPoint(x: cx + r * 0.86, y: cy - r * 0.5))
            top.addLine(to: CGPoint(x: cx, y: cy))
            top.addLine(to: CGPoint(x: cx - r * 0.86, y: cy - r * 0.5))
            top.closeSubpath()
            context.stroke(top, with: .color(color), lineWidth: w * 0.09)
            
            // Left facet
            var left = Path()
            left.move(to: CGPoint(x: cx - r * 0.86, y: cy - r * 0.5))
            left.addLine(to: CGPoint(x: cx, y: cy))
            left.addLine(to: CGPoint(x: cx, y: cy + r))
            left.addLine(to: CGPoint(x: cx - r * 0.86, y: cy + r * 0.5))
            left.closeSubpath()
            context.stroke(left, with: .color(color), lineWidth: w * 0.09)
            
            // Right facet
            var right = Path()
            right.move(to: CGPoint(x: cx + r * 0.86, y: cy - r * 0.5))
            right.addLine(to: CGPoint(x: cx, y: cy))
            right.addLine(to: CGPoint(x: cx, y: cy + r))
            right.addLine(to: CGPoint(x: cx + r * 0.86, y: cy + r * 0.5))
            right.closeSubpath()
            context.stroke(right, with: .color(color), lineWidth: w * 0.09)
        }
        .frame(width: size, height: size)
    }
}

public struct ProviderBrandIcon: View {
    public var provider: AIProviderType
    public var size: CGFloat = 20
    public var color: Color = .white
    
    public var body: some View {
        switch provider {
        case .claude:
            ClaudeStarburstIcon(size: size, color: color)
        case .cursor:
            Image(systemName: "chevron.right")
                .font(.system(size: size * 0.7, weight: .bold))
                .foregroundColor(color)
        case .antigravity:
            IsometricCubeIcon(size: size, color: color)
        case .claudeCode:
            Image(systemName: "terminal.fill")
                .font(.system(size: size * 0.65, weight: .semibold))
                .foregroundColor(color)
        case .kiro:
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: size * 0.7, weight: .semibold))
                .foregroundColor(color)
        }
    }
}
