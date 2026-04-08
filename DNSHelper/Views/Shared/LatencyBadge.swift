import SwiftUI

struct LatencyBadge: View {
    let ms: Double

    private var rating: LatencyRating { .from(ms: ms) }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: rating.sfSymbol)
                .font(.system(size: 9))
            Text(rating.rawValue)
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background {
            Capsule()
                .fill(rating.color.opacity(0.15))
        }
        .foregroundStyle(rating.color)
    }
}

struct LatencyValueView: View {
    let label: String
    let ms: Double

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f", ms))
                .font(.latencyValue)
                .foregroundStyle(.primary)
            Text("ms")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
