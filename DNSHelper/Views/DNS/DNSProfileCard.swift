import SwiftUI

struct DNSProfileCard: View {
    let profile: DNSProfile
    let isActive: Bool
    var onApply: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                profileIcon
                profileInfo
                Spacer()
                activeIndicator
            }

            dnsAddresses

            HStack {
                benchmarkInfo
                Spacer()
                applyButton
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card)
                        .strokeBorder(
                            isActive ? profile.brandColor : .clear,
                            lineWidth: isActive ? 2 : 0
                        )
                }
        }
        .shadow(
            color: isHovering ? DesignTokens.Shadow.popoverColor : DesignTokens.Shadow.cardColor,
            radius: isHovering ? 8 : DesignTokens.Shadow.cardRadius,
            y: DesignTokens.Shadow.cardY
        )
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
    }

    // MARK: - Subviews

    private var profileIcon: some View {
        Circle()
            .fill(profile.brandColor.gradient)
            .frame(width: DesignTokens.IconSize.xl, height: DesignTokens.IconSize.xl)
            .overlay {
                Image(systemName: profile.sfSymbol)
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .semibold))
            }
    }

    private var profileInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(profile.name)
                .font(.cardTitle)
            Text(profile.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var activeIndicator: some View {
        if isActive {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.dnsSuccess)
                .font(.system(size: 20))
                .symbolEffect(.bounce, value: isActive)
        }
    }

    private var dnsAddresses: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            Label {
                Text(profile.primaryDNS)
                    .font(.ipAddress)
            } icon: {
                Image(systemName: "1.circle.fill")
                    .foregroundStyle(profile.brandColor)
                    .font(.system(size: 12))
            }

            Label {
                Text(profile.secondaryDNS)
                    .font(.ipAddress)
            } icon: {
                Image(systemName: "2.circle.fill")
                    .foregroundStyle(profile.brandColor.opacity(0.6))
                    .font(.system(size: 12))
            }
        }
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var benchmarkInfo: some View {
        if let ms = profile.lastBenchmarkMS {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "speedometer")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(String(format: "%.1f ms", ms))
                    .font(.latencyValue)
                LatencyBadge(ms: ms)
            }
        } else {
            Text("No benchmark")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var applyButton: some View {
        Button {
            onApply()
        } label: {
            Text(isActive ? "Active" : "Apply")
                .font(.system(.caption, weight: .medium))
        }
        .buttonStyle(.borderedProminent)
        .tint(isActive ? Color.dnsSuccess : profile.brandColor)
        .disabled(isActive)
        .controlSize(.small)
    }
}
