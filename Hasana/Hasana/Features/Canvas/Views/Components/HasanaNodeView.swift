import SwiftUI

struct HasanaNodeView: View {
    let node: HasanaCanvasNode
    let isDragging: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(node.theme.color.opacity(0.16))

                Image(systemName: node.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(node.theme.color)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(node.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HasanaTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(node.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HasanaTheme.textMuted)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .frame(width: 240)
        .frame(minHeight: 88)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .background(HasanaTheme.elevatedSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isDragging ? node.theme.color.opacity(0.7) : HasanaTheme.border.opacity(0.78), lineWidth: isDragging ? 1.4 : 0.7)
        )
        .shadow(color: node.theme.color.opacity(isDragging ? 0.32 : node.theme.glowOpacity), radius: isDragging ? 22 : 14, x: 0, y: isDragging ? 14 : 8)
        .scaleEffect(isDragging ? 1.035 : 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isDragging)
    }
}
