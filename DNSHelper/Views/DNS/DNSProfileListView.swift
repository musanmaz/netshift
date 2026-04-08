import SwiftUI

struct DNSProfileListView: View {
    @EnvironmentObject var dnsManager: DNSManager

    var body: some View {
        List {
            Section {
                ForEach(dnsManager.profiles) { profile in
                    profileRow(profile)
                }
            } header: {
                sectionHeader("DNS PROFILES", icon: "antenna.radiowaves.left.and.right")
            }

            Section {
                statusSummary
            } header: {
                sectionHeader("CURRENT STATUS", icon: "info.circle")
            }
        }
    }

    private func profileRow(_ profile: DNSProfile) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Circle()
                .fill(profile.brandColor.gradient)
                .frame(width: 24, height: 24)
                .overlay {
                    Image(systemName: profile.sfSymbol)
                        .foregroundStyle(.white)
                        .font(.system(size: 11, weight: .semibold))
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(profile.name)
                    .font(.system(.body, weight: profile.isActive ? .semibold : .regular))
                Text(profile.primaryDNS)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if profile.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.dnsSuccess)
                    .symbolEffect(.bounce, value: profile.isActive)
            }
        }
        .padding(.vertical, 2)
    }

    private var statusSummary: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            if let active = dnsManager.profiles.first(where: \.isActive) {
                Label("Active: \(active.name)", systemImage: "checkmark.shield.fill")
                    .foregroundStyle(Color.dnsSuccess)
                    .font(.callout)
            } else {
                Label("DHCP / Custom DNS", systemImage: "network")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(title)
                .font(.sectionHeader)
        }
        .foregroundStyle(.secondary)
    }
}
