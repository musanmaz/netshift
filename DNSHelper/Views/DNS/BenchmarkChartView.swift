import SwiftUI
import Charts

struct BenchmarkChartView: View {
    let results: [BenchmarkResult]

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            chartView
            legendView
            detailTable
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart(results) { result in
            BarMark(
                x: .value("Profile", result.profileName),
                y: .value("Latency", result.avgMS)
            )
            .foregroundStyle(colorForProfile(result.id).gradient)
            .cornerRadius(4)
            .annotation(position: .top, spacing: 4) {
                Text(String(format: "%.0f", result.avgMS))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxisLabel("Latency (ms)")
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(.quaternary)
                AxisValueLabel {
                    Text("\(value.as(Double.self) ?? 0, specifier: "%.0f")")
                        .font(.caption2)
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    Text(value.as(String.self) ?? "")
                        .font(.caption)
                }
            }
        }
        .frame(height: 200)
        .padding(.horizontal, DesignTokens.Spacing.sm)
    }

    // MARK: - Legend

    private var legendView: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            ForEach(results, id: \.id) { result in
                HStack(spacing: 4) {
                    Circle()
                        .fill(colorForProfile(result.id))
                        .frame(width: 8, height: 8)
                    Text(result.profileName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Detail Table

    private var detailTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Profile").frame(width: 100, alignment: .leading)
                Text("AVG").frame(width: 60)
                Text("P50").frame(width: 60)
                Text("P90").frame(width: 60)
                Text("Success").frame(width: 60)
                Spacer()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.vertical, DesignTokens.Spacing.sm)

            Divider()

            ForEach(results, id: \.id) { result in
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(colorForProfile(result.id))
                            .frame(width: 6, height: 6)
                        Text(result.profileName)
                    }
                    .frame(width: 100, alignment: .leading)

                    Text(String(format: "%.1f", result.avgMS))
                        .frame(width: 60)
                    Text(String(format: "%.1f", result.p50MS))
                        .frame(width: 60)
                    Text(String(format: "%.1f", result.p90MS))
                        .frame(width: 60)
                    Text(String(format: "%.0f%%", result.successRate))
                        .foregroundStyle(result.successRate >= 90 ? Color.dnsSuccess : Color.dnsWarning)
                        .frame(width: 60)
                    Spacer()
                    LatencyBadge(ms: result.avgMS)
                }
                .font(.system(.caption, design: .monospaced))
                .padding(.vertical, DesignTokens.Spacing.xs)

                if result.id != results.last?.id {
                    Divider()
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                .fill(.quaternary.opacity(0.3))
        }
    }

    private func colorForProfile(_ id: String) -> Color {
        switch id {
        case "cloudflare": return .cloudflareOrange
        case "google": return .googleBlue
        case "quad9": return .quad9Purple
        case "opendns": return .opendnsYellow
        default: return .dnsAccent
        }
    }
}
