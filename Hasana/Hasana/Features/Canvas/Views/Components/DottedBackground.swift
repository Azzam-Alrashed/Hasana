import SwiftUI

struct DottedBackground: View {
    let offset: CGSize
    let scale: CGFloat

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            let baseSpacing: CGFloat = 28
            let spacing = max(baseSpacing * scale, 8)
            let dotRadius = max(1.15 * min(scale, 1.35), 0.75)
            let originX = offset.width.truncatingRemainder(dividingBy: spacing)
            let originY = offset.height.truncatingRemainder(dividingBy: spacing)

            func drawLevel(multiplier: CGFloat, alpha: Double, radiusMultiplier: CGFloat) {
                let levelSpacing = spacing * multiplier
                let startX = originX.truncatingRemainder(dividingBy: levelSpacing) - levelSpacing
                let startY = originY.truncatingRemainder(dividingBy: levelSpacing) - levelSpacing
                let radius = dotRadius * radiusMultiplier
                var dots = Path()

                var x = startX
                while x < size.width + levelSpacing {
                    var y = startY
                    while y < size.height + levelSpacing {
                        dots.addEllipse(in: CGRect(
                            x: x - radius,
                            y: y - radius,
                            width: radius * 2,
                            height: radius * 2
                        ))
                        y += levelSpacing
                    }
                    x += levelSpacing
                }

                context.fill(dots, with: .color(HasanaTheme.textPrimary.opacity(alpha)))
            }

            drawLevel(multiplier: 4, alpha: 0.08, radiusMultiplier: 1.7)
            drawLevel(multiplier: 2, alpha: 0.06, radiusMultiplier: 1.25)
            drawLevel(multiplier: 1, alpha: 0.045, radiusMultiplier: 1)
        }
        .ignoresSafeArea()
        .background(
            HasanaTheme.canvasBackground
                .ignoresSafeArea()
        )
    }
}
