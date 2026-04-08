import SwiftUI

struct SkeletonLoader: View {
    var lineCount: Int = 5
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ForEach(0..<lineCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(height: 14)
                    .frame(maxWidth: lineWidth(for: index))
                    .opacity(isAnimating ? 0.4 : 0.8)
                    .animation(
                        .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .padding()
        .onAppear { isAnimating = true }
    }

    private func lineWidth(for index: Int) -> CGFloat {
        let widths: [CGFloat] = [.infinity, 280, .infinity, 200, 320]
        return widths[index % widths.count]
    }
}

struct SkeletonCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Circle()
                    .fill(.quaternary)
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.quaternary)
                        .frame(width: 120, height: 14)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.quaternary)
                        .frame(width: 180, height: 10)
                }
            }
            RoundedRectangle(cornerRadius: 3)
                .fill(.quaternary)
                .frame(height: 10)
                .frame(maxWidth: 200)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card)
                .fill(.regularMaterial)
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}
