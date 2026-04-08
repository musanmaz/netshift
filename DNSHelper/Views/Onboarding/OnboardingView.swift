import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @ObservedObject private var helper = PrivilegedHelper.shared
    @State private var isInstalling = false
    @State private var installError: String?
    @State private var installSuccess = false
    var onComplete: () -> Void

    private let totalPages = 4

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch currentPage {
                case 0: welcomePage
                case 1: permissionPage
                case 2: quickStartPage
                default: setupPage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            bottomControls
        }
        .frame(width: 460, height: 420)
        .background(.regularMaterial)
    }

    // MARK: - Welcome

    private var welcomePage: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "network.badge.shield.half.filled")
                .font(.system(size: 52))
                .foregroundStyle(Color.dnsAccent.gradient)
                .symbolRenderingMode(.hierarchical)

            Text("Welcome to NetShift")
                .font(.title2)
                .fontWeight(.bold)

            Text("Easily manage your DNS servers\nand hosts file.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Permission

    private var permissionPage: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 44))
                .foregroundStyle(Color.dnsWarning.gradient)
                .symbolRenderingMode(.hierarchical)

            Text("Admin Access Required")
                .font(.title3)
                .fontWeight(.bold)

            Text("Administrator privileges are needed to\nmodify /etc/hosts and DNS settings.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(Color.dnsSuccess)
                    .font(.callout)
                Text("Password is only asked once during setup")
                    .font(.caption)
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.dnsSuccess.opacity(0.08))
            }

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Quick Start

    private var quickStartPage: some View {
        VStack(spacing: 14) {
            Spacer()

            Text("Quick Start")
                .font(.title3)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                featureCard(
                    icon: "doc.text.fill",
                    color: .dnsAccent,
                    title: "Hosts Files",
                    desc: "Switch between different hosts files"
                )
                featureCard(
                    icon: "antenna.radiowaves.left.and.right",
                    color: .cloudflareOrange,
                    title: "DNS Profiles",
                    desc: "Change DNS servers with one click"
                )
                featureCard(
                    icon: "speedometer",
                    color: .dnsSuccess,
                    title: "Benchmark",
                    desc: "Find the fastest DNS server"
                )
            }

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Setup

    private var setupPage: some View {
        VStack(spacing: 16) {
            Spacer()

            if installSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.dnsSuccess.gradient)
                    .symbolRenderingMode(.hierarchical)

                Text("Setup Complete!")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("All operations will now work\nwithout asking for a password.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.dnsAccent.gradient)
                    .symbolRenderingMode(.hierarchical)

                Text("Complete Setup")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("A helper tool will be installed and your\nadmin password will be asked one time.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let installError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.dnsDanger)
                        Text(installError)
                            .font(.caption)
                            .foregroundStyle(Color.dnsDanger)
                    }
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.dnsDanger.opacity(0.08))
                    }
                }

                Button {
                    performSetup()
                } label: {
                    HStack(spacing: 8) {
                        if isInstalling {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(isInstalling ? "Installing..." : "Start Setup")
                    }
                    .frame(minWidth: 180)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isInstalling)
            }

            Spacer()
        }
        .padding(24)
    }

    private func featureCard(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.1))
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.dnsAccent : Color.secondary.opacity(0.3))
                        .frame(width: 7, height: 7)
                }
            }

            Spacer()

            if currentPage > 0 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentPage -= 1
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }

            if currentPage < totalPages - 1 {
                Button("Continue") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentPage += 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            } else if installSuccess {
                Button("Get Started") {
                    AppSettings.shared.helperInstalled = true
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(Color.dnsSuccess)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.bar)
    }

    // MARK: - Setup Logic

    private func performSetup() {
        isInstalling = true
        installError = nil

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try PrivilegedHelper.shared.setup()
                DispatchQueue.main.async {
                    withAnimation {
                        installSuccess = true
                    }
                    isInstalling = false
                }
            } catch {
                DispatchQueue.main.async {
                    installError = error.localizedDescription
                    isInstalling = false
                }
            }
        }
    }
}
