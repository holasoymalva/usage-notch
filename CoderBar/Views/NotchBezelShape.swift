//
//  NotchBezelShape.swift
//  Usage Notch
//

import SwiftUI

public struct NotchBezelShape: Shape {
    public var position: NotchPosition
    public var flareHeight: CGFloat = 38
    public var flareWidth: CGFloat = 30
    public var cornerRadius: CGFloat = 24
    public var isOutlineOnly: Bool = false
    
    public func path(in rect: CGRect) -> Path {
        switch position {
        case .leftEdge:
            return leftEdgePath(in: rect)
        case .rightEdge:
            return rightEdgePath(in: rect)
        case .topNotch:
            return topNotchPath(in: rect)
        }
    }
    
    // Protrudes from the left display border (x = 0) towards the right
    private func leftEdgePath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        let fh = min(flareHeight, h * 0.20)
        let fw = min(flareWidth, w * 0.45)
        let r = min(cornerRadius, min(w - fw - 2, 26))
        
        // Start at screen edge (0, 0) with vertical tangent
        path.move(to: CGPoint(x: 0, y: 0))
        
        // 1. Top concave flare: sweeps down & out from screen bezel to horizontal bridge
        path.addCurve(
            to: CGPoint(x: fw, y: fh),
            control1: CGPoint(x: 0, y: fh * 0.55),
            control2: CGPoint(x: fw * 0.45, y: fh)
        )
        
        // 2. Horizontal bridge leading to the rounded shoulder
        path.addLine(to: CGPoint(x: w - r, y: fh))
        
        // 3. Convex corner rounding into the vertical wall
        path.addArc(
            center: CGPoint(x: w - r, y: fh + r),
            radius: r,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        // 4. Vertical outer edge
        path.addLine(to: CGPoint(x: w, y: h - (fh + r)))
        
        // 5. Bottom convex corner rounding into the bottom bridge
        path.addArc(
            center: CGPoint(x: w - r, y: h - (fh + r)),
            radius: r,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        
        // 6. Horizontal bottom bridge
        path.addLine(to: CGPoint(x: fw, y: h - fh))
        
        // 7. Bottom concave flare sweeping back to meet the screen bezel (0, h)
        path.addCurve(
            to: CGPoint(x: 0, y: h),
            control1: CGPoint(x: fw * 0.45, y: h - fh),
            control2: CGPoint(x: 0, y: h - fh * 0.55)
        )
        
        if !isOutlineOnly {
            // Close path along the screen edge (x = 0)
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.closeSubpath()
        }
        
        return path
    }
    
    // Protrudes from the right display border (x = w) towards the left
    private func rightEdgePath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        let fh = min(flareHeight, h * 0.20)
        let fw = min(flareWidth, w * 0.45)
        let r = min(cornerRadius, min(w - fw - 2, 26))
        
        // Start at screen edge (w, 0) with vertical tangent
        path.move(to: CGPoint(x: w, y: 0))
        
        // 1. Top concave flare sweeping inwards
        path.addCurve(
            to: CGPoint(x: w - fw, y: fh),
            control1: CGPoint(x: w, y: fh * 0.55),
            control2: CGPoint(x: w - fw * 0.45, y: fh)
        )
        
        // 2. Horizontal bridge
        path.addLine(to: CGPoint(x: r, y: fh))
        
        // 3. Top-left convex corner
        path.addArc(
            center: CGPoint(x: r, y: fh + r),
            radius: r,
            startAngle: .degrees(270),
            endAngle: .degrees(180),
            clockwise: true
        )
        
        // 4. Vertical outer edge
        path.addLine(to: CGPoint(x: 0, y: h - (fh + r)))
        
        // 5. Bottom-left convex corner
        path.addArc(
            center: CGPoint(x: r, y: h - (fh + r)),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )
        
        // 6. Horizontal bottom bridge
        path.addLine(to: CGPoint(x: w - fw, y: h - fh))
        
        // 7. Bottom concave flare back to screen edge (w, h)
        path.addCurve(
            to: CGPoint(x: w, y: h),
            control1: CGPoint(x: w - fw * 0.45, y: h - fh),
            control2: CGPoint(x: w, y: h - fh * 0.55)
        )
        
        if !isOutlineOnly {
            path.addLine(to: CGPoint(x: w, y: 0))
            path.closeSubpath()
        }
        
        return path
    }
    
    // Protrudes downward from top display notch
    private func topNotchPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        let fw = min(flareWidth, w * 0.15)
        let fh = min(flareHeight, h * 0.25)
        let r = min(cornerRadius, h * 0.40)
        
        path.move(to: CGPoint(x: 0, y: 0))
        
        path.addCurve(
            to: CGPoint(x: fw, y: fh),
            control1: CGPoint(x: fw * 0.55, y: 0),
            control2: CGPoint(x: fw, y: fh * 0.45)
        )
        
        path.addLine(to: CGPoint(x: fw, y: h - r))
        
        path.addArc(
            center: CGPoint(x: fw + r, y: h - r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )
        
        path.addLine(to: CGPoint(x: w - (fw + r), y: h))
        
        path.addArc(
            center: CGPoint(x: w - (fw + r), y: h - r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(0),
            clockwise: true
        )
        
        path.addLine(to: CGPoint(x: w - fw, y: fh))
        
        path.addCurve(
            to: CGPoint(x: w, y: 0),
            control1: CGPoint(x: w - fw, y: fh * 0.45),
            control2: CGPoint(x: w - fw * 0.55, y: 0)
        )
        
        if !isOutlineOnly {
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.closeSubpath()
        }
        
        return path
    }
}

public struct PopoverBezelShape: Shape {
    public var arrowPosition: NotchPosition // .leftEdge = dock on left, popover on right with arrow pointing left
    public var arrowY: CGFloat // Vertical Y of the arrow tip
    public var arrowWidth: CGFloat = 8
    public var arrowHeight: CGFloat = 14
    public var cornerRadius: CGFloat = 18
    
    public var animatableData: CGFloat {
        get { arrowY }
        set { arrowY = newValue }
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = cornerRadius
        let aw = arrowWidth
        let ah = arrowHeight
        
        let clampedY = max(r + ah / 2 + 2, min(rect.height - r - ah / 2 - 2, arrowY))
        
        if arrowPosition != .rightEdge {
            // Dock is on the left; Popover arrow is on the left edge pointing left
            let bodyLeft = rect.minX + aw
            let bodyRight = rect.maxX
            let bodyTop = rect.minY
            let bodyBottom = rect.maxY
            
            path.move(to: CGPoint(x: bodyLeft + r, y: bodyTop))
            
            // Top edge
            path.addLine(to: CGPoint(x: bodyRight - r, y: bodyTop))
            // Top-right corner
            path.addArc(center: CGPoint(x: bodyRight - r, y: bodyTop + r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            // Right edge
            path.addLine(to: CGPoint(x: bodyRight, y: bodyBottom - r))
            // Bottom-right corner
            path.addArc(center: CGPoint(x: bodyRight - r, y: bodyBottom - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            // Bottom edge
            path.addLine(to: CGPoint(x: bodyLeft + r, y: bodyBottom))
            // Bottom-left corner
            path.addArc(center: CGPoint(x: bodyLeft + r, y: bodyBottom - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            
            // Left edge up to bottom of arrow
            path.addLine(to: CGPoint(x: bodyLeft, y: clampedY + ah / 2))
            // Arrow tip pointing left
            path.addLine(to: CGPoint(x: rect.minX, y: clampedY))
            // Arrow top base
            path.addLine(to: CGPoint(x: bodyLeft, y: clampedY - ah / 2))
            
            // Left edge up to top-left corner
            path.addLine(to: CGPoint(x: bodyLeft, y: bodyTop + r))
            // Top-left corner
            path.addArc(center: CGPoint(x: bodyLeft + r, y: bodyTop + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            path.closeSubpath()
        } else {
            // Dock is on the right; Popover arrow is on the right edge pointing right
            let bodyLeft = rect.minX
            let bodyRight = rect.maxX - aw
            let bodyTop = rect.minY
            let bodyBottom = rect.maxY
            
            path.move(to: CGPoint(x: bodyLeft + r, y: bodyTop))
            path.addLine(to: CGPoint(x: bodyRight - r, y: bodyTop))
            path.addArc(center: CGPoint(x: bodyRight - r, y: bodyTop + r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            
            // Right edge down to top of arrow
            path.addLine(to: CGPoint(x: bodyRight, y: clampedY - ah / 2))
            // Arrow tip pointing right
            path.addLine(to: CGPoint(x: rect.maxX, y: clampedY))
            // Arrow bottom base
            path.addLine(to: CGPoint(x: bodyRight, y: clampedY + ah / 2))
            
            path.addLine(to: CGPoint(x: bodyRight, y: bodyBottom - r))
            path.addArc(center: CGPoint(x: bodyRight - r, y: bodyBottom - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: bodyLeft + r, y: bodyBottom))
            path.addArc(center: CGPoint(x: bodyLeft + r, y: bodyBottom - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: bodyLeft, y: bodyTop + r))
            path.addArc(center: CGPoint(x: bodyLeft + r, y: bodyTop + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            path.closeSubpath()
        }
        return path
    }
}
