import SwiftUI

struct BenchmarkResultRow: View {
    let result: BenchmarkResult

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            Text(result.profileName)
                .font(.callout)
                .fontWeight(.medium)
                .frame(width: 100, alignment: .leading)

            LatencyValueView(label: "AVG", ms: result.avgMS)
            LatencyValueView(label: "P50", ms: result.p50MS)
            LatencyValueView(label: "P90", ms: result.p90MS)

            Spacer()

            VStack(spacing: 2) {
                Text("Success")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f%%", result.successRate))
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(result.successRate >= 90 ? Color.dnsSuccess : Color.dnsWarning)
            }

            LatencyBadge(ms: result.avgMS)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

struct BenchmarkDetailView: View {
    let results: [BenchmarkResult]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Detailed Results")
                .font(.headline)

            Divider()

            ForEach(results) { result in
                BenchmarkResultRow(result: result)
                if result.id != results.last?.id {
                    Divider()
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }
}
