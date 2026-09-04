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

public struct AntigravityArchIcon: View {
    public var size: CGFloat = 20
    public var color: Color = .white
    
    public init(size: CGFloat = 20, color: Color = .white) {
        self.size = size
        self.color = color
    }
    
    public var body: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height
            var path = Path()
            // Symmetrical upward arch with flared feet
            path.move(to: CGPoint(x: w * 0.23, y: h * 0.82))
            path.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.20), control: CGPoint(x: w * 0.27, y: h * 0.35))
            path.addQuadCurve(to: CGPoint(x: w * 0.77, y: h * 0.82), control: CGPoint(x: w * 0.73, y: h * 0.35))
            
            context.stroke(
                path,
                with: .color(color),
                style: StrokeStyle(lineWidth: w * 0.21, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: size, height: size)
    }
}

public struct CopilotIcon: View {
    public var size: CGFloat = 20
    public var color: Color = .white
    
    public init(size: CGFloat = 20, color: Color = .white) {
        self.size = size
        self.color = color
    }
    
    public var body: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height
            
            // Helmet / Head contour
            let headRect = CGRect(x: w * 0.20, y: h * 0.20, width: w * 0.60, height: h * 0.58)
            let headPath = Path(roundedRect: headRect, cornerRadius: w * 0.24)
            context.stroke(headPath, with: .color(color), lineWidth: w * 0.09)
            
            // Left & Right earcups / headphones
            let leftEar = Path(roundedRect: CGRect(x: w * 0.08, y: h * 0.35, width: w * 0.12, height: h * 0.30), cornerRadius: w * 0.06)
            context.fill(leftEar, with: .color(color))
            
            let rightEar = Path(roundedRect: CGRect(x: w * 0.80, y: h * 0.35, width: w * 0.12, height: h * 0.30), cornerRadius: w * 0.06)
            context.fill(rightEar, with: .color(color))
            
            // Visor across the face
            let visorRect = CGRect(x: w * 0.27, y: h * 0.40, width: w * 0.46, height: h * 0.20)
            let visorPath = Path(roundedRect: visorRect, cornerRadius: w * 0.10)
            context.stroke(visorPath, with: .color(color), lineWidth: w * 0.08)
            
            // Two glowing eyes inside visor
            let eyeRadius = w * 0.042
            let leftEye = Path(ellipseIn: CGRect(x: w * 0.37 - eyeRadius, y: h * 0.50 - eyeRadius, width: eyeRadius * 2, height: eyeRadius * 2))
            context.fill(leftEye, with: .color(color))
            
            let rightEye = Path(ellipseIn: CGRect(x: w * 0.63 - eyeRadius, y: h * 0.50 - eyeRadius, width: eyeRadius * 2, height: eyeRadius * 2))
            context.fill(rightEye, with: .color(color))
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
        case .antigravity:
            AntigravityArchIcon(size: size, color: color)
        case .codex:
            OpenAISpiralIcon(size: size, color: color)
        case .copilot:
            CopilotIcon(size: size, color: color)
        case .claude:
            ClaudeStarburstIcon(size: size, color: color)
        case .cursor:
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
