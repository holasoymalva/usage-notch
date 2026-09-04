//
//  NotchBezelShape.swift
//  Usage Notch
//

import SwiftUI

public struct NotchBezelShape: Shape {
    public var position: NotchPosition
    public var filletRadius: CGFloat = 18
    public var cornerRadius: CGFloat = 22
    
    public func path(in rect: CGRect) -> Path {
        switch position {
        case .rightEdge:
            return rightEdgePath(in: rect)
        case .leftEdge:
            return leftEdgePath(in: rect)
        case .topNotch:
            return topNotchPath(in: rect)
        }
    }
    
    // Protrudes from the right display border towards the left
    private func rightEdgePath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Determine fillet and corner dynamically based on available height
        let f = min(filletRadius, h * 0.22)
        let r = min(cornerRadius, (h - 2 * f) * 0.5)
        
        // Start top-right at screen edge
        path.move(to: CGPoint(x: w, y: 0))
        
        // Top concave curve flaring from screen edge (w, 0) to tab edge (r, f)
        path.addCurve(
            to: CGPoint(x: r, y: f),
            control1: CGPoint(x: w * 0.35, y: 0),
            control2: CGPoint(x: r, y: f * 0.3)
        )
        
        // Top-left convex corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: f + r),
            control: CGPoint(x: 0, y: f)
        )
        
        // Left vertical edge
        path.addLine(to: CGPoint(x: 0, y: h - (f + r)))
        
        // Bottom-left convex corner
        path.addQuadCurve(
            to: CGPoint(x: r, y: h - f),
            control: CGPoint(x: 0, y: h - f)
        )
        
        // Bottom concave curve flaring back to screen edge (w, h)
        path.addCurve(
            to: CGPoint(x: w, y: h),
            control1: CGPoint(x: r, y: h - f * 0.3),
            control2: CGPoint(x: w * 0.35, y: h)
        )
        
        // Close along the right border
        path.addLine(to: CGPoint(x: w, y: 0))
        path.closeSubpath()
        return path
    }
    
    // Protrudes from the left display border towards the right
    private func leftEdgePath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        let f = min(filletRadius, h * 0.22)
        let r = min(cornerRadius, (h - 2 * f) * 0.5)
        
        path.move(to: CGPoint(x: 0, y: 0))
        
        path.addCurve(
            to: CGPoint(x: w - r, y: f),
            control1: CGPoint(x: w * 0.65, y: 0),
            control2: CGPoint(x: w - r, y: f * 0.3)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: w, y: f + r),
            control: CGPoint(x: w, y: f)
        )
        
        path.addLine(to: CGPoint(x: w, y: h - (f + r)))
        
        path.addQuadCurve(
            to: CGPoint(x: w - r, y: h - f),
            control: CGPoint(x: w, y: h - f)
        )
        
        path.addCurve(
            to: CGPoint(x: 0, y: h),
            control1: CGPoint(x: w - r, y: h - f * 0.3),
            control2: CGPoint(x: w * 0.65, y: h)
        )
        
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
    
    // Protrudes downward from top display notch
    private func topNotchPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        let f = min(filletRadius, w * 0.18)
        let r = min(cornerRadius, h * 0.45)
        
        path.move(to: CGPoint(x: 0, y: 0))
        
        path.addCurve(
            to: CGPoint(x: f, y: h - r),
            control1: CGPoint(x: 0, y: h * 0.35),
            control2: CGPoint(x: f * 0.3, y: h - r)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: f + r, y: h),
            control: CGPoint(x: f, y: h)
        )
        
        path.addLine(to: CGPoint(x: w - (f + r), y: h))
        
        path.addQuadCurve(
            to: CGPoint(x: w - f, y: h - r),
            control: CGPoint(x: w - f, y: h)
        )
        
        path.addCurve(
            to: CGPoint(x: w, y: 0),
            control1: CGPoint(x: w - f * 0.3, y: h - r),
            control2: CGPoint(x: w, y: h * 0.35)
        )
        
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}
