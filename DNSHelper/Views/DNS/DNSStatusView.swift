import SwiftUI

struct DNSStatusView: View {
    @EnvironmentObject var dnsManager: DNSManager
    @StateObject private var benchmark = DNSBenchmark()
    @State private var toast: ToastData?
    @State private var showCustomDNSSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                currentStatusCard
                profileCardsGrid
                benchmarkSection
            }
            .padding(DesignTokens.Spacing.xl)
        }
        .toast($toast)
        .sheet(isPresented: $showCustomDNSSheet) {
            CustomDNSSheet { primary, secondary in
                applyCustom(primary: primary, secondary: secondary)
            }
        }
    }

    // MARK: - Current Status

    private var currentStatusCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Label("Active DNS Status", systemImage: "network.badge.shield.half.filled")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()

                Button {
                    dnsManager.refreshStatus()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)

                Button("Custom DNS") {
                    showCustomDNSSheet = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Reset to DHCP") {
                    resetDNS()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(Color.dnsWarning)
            }

            if dnsManager.networkServices.isEmpty {
                SkeletonLoader(lineCount: 3)
            } else {
                ForEach(dnsManager.networkServices) { service in
                    HStack {
                        Image(systemName: "wifi")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        Text(service.name)
                            .font(.callout)
                        Spacer()
                        if service.dnsServers.isEmpty {
                            Text("DHCP")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        } else {
                            Text(service.dnsServers.joined(separator: ", "))
                                .font(.ipAddress)
                                .foregroundStyle(Color.dnsAccent)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card)
                .fill(.regularMaterial)
        }
        .shadow(color: DesignTokens.Shadow.cardColor, radius: DesignTokens.Shadow.cardRadius, y: DesignTokens.Shadow.cardY)
    }

    // MARK: - Profile Cards

    private var profileCardsGrid: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("DNS Profiles")
                .font(.title3)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
                GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
            ], spacing: DesignTokens.Spacing.md) {
                ForEach(dnsManager.profiles) { profile in
                    DNSProfileCard(
                        profile: profile,
                        isActive: profile.isActive
                    ) {
                        applyProfile(profile)
                    }
                }
            }
        }
    }

    // MARK: - Benchmark

    private var benchmarkSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Label("Benchmark", systemImage: "speedometer")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()

                if benchmark.isRunning {
                    ProgressView()
                        .controlSize(.small)
                    Text(benchmark.currentProfile)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    runBenchmark()
                } label: {
                    Label("Run", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(benchmark.isRunning)
            }

            if benchmark.isRunning {
                ProgressView(value: benchmark.progress)
                    .progressViewStyle(.linear)
                    .tint(Color.dnsAccent)
            }

            if !benchmark.results.isEmpty {
                BenchmarkChartView(results: benchmark.results)
            } else if !benchmark.isRunning {
                EmptyStateView(
                    icon: "speedometer",
                    title: "No Benchmark Yet",
                    message: "Run a benchmark to compare DNS profile performance."
                )
                .frame(height: 200)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card)
                .fill(.regularMaterial)
        }
        .shadow(color: DesignTokens.Shadow.cardColor, radius: DesignTokens.Shadow.cardRadius, y: DesignTokens.Shadow.cardY)
    }

    // MARK: - Actions

    private func applyProfile(_ profile: DNSProfile) {
        do {
            try dnsManager.applyProfile(profile)
            withAnimation { toast = ToastData(message: "DNS switched to \(profile.name)", style: .success) }
        } catch {
            withAnimation { toast = ToastData(message: error.localizedDescription, style: .error) }
        }
    }

    private func applyCustom(primary: String, secondary: String) {
        do {
            try dnsManager.applyCustomDNS(primary: primary, secondary: secondary)
            withAnimation { toast = ToastData(message: "Custom DNS applied", style: .success) }
        } catch {
            withAnimation { toast = ToastData(message: error.localizedDescription, style: .error) }
        }
    }

    private func resetDNS() {
        do {
            try dnsManager.resetToDHCP()
            withAnimation { toast = ToastData(message: "DNS reset to DHCP", style: .success) }
        } catch {
            withAnimation { toast = ToastData(message: error.localizedDescription, style: .error) }
        }
    }

    private func runBenchmark() {
        Task { await benchmark.runBenchmark(profiles: dnsManager.profiles) }
    }
}

// MARK: - Custom DNS Sheet

struct CustomDNSSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var primary = ""
    @State private var secondary = ""
    var onApply: (String, String) -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Label("Custom DNS Servers", systemImage: "server.rack")
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                TextField("Primary DNS", text: $primary)
                    .textFieldStyle(.roundedBorder)
                    .font(.ipAddress)
                TextField("Secondary DNS", text: $secondary)
                    .textFieldStyle(.roundedBorder)
                    .font(.ipAddress)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Apply") {
                    onApply(primary, secondary)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(primary.isEmpty)
                .keyboardShortcut(.return)
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(width: 380)
    }
}
