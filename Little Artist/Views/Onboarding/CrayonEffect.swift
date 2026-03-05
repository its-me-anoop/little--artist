import SwiftUI

/// A custom modifier that applies a slight rotation and hand-drawn distortion effect
/// to make text and components look like they were drawn by a child with a crayon.
struct CrayonEffect: ViewModifier {
    let rotationDegrees: Double
    let scale: CGFloat
    let offset: CGPoint
    
    init() {
        // Randomise slightly each time for a hand-drawn feel
        self.rotationDegrees = Double.random(in: -2...2)
        self.scale = CGFloat.random(in: 0.98...1.02)
        self.offset = CGPoint(x: CGFloat.random(in: -1...1), y: CGFloat.random(in: -1...1))
    }
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotationDegrees))
            .scaleEffect(scale)
            .offset(x: offset.x, y: offset.y)
    }
}

extension View {
    /// Applies a subtle, randomised hand-drawn crayon effect (rotation, scale, offset).
    func crayonStyle() -> some View {
        modifier(CrayonEffect())
    }
}
