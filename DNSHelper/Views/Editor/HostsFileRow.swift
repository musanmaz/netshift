import SwiftUI

struct HostsFileRow: View {
    let file: HostsFile
    let isActive: Bool

    @EnvironmentObject var hostsManager: HostsFileManager

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { isActive },
            set: { newValue in
                if newValue && !isActive {
                    try? hostsManager.activateFile(file)
                }
            }
        )
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: file.type.sfSymbol)
                .foregroundStyle(iconColor)
                .font(.system(size: DesignTokens.IconSize.sm))
                .frame(width: 16)

            Text(file.name)
                .font(.system(.body, weight: isActive ? .semibold : .regular))
                .lineLimit(1)

            Spacer()

            if file.type == .remote {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            Toggle("", isOn: toggleBinding)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .tint(Color.dnsSuccess)
        }
        .padding(.vertical, 2)
        .contextMenu { contextMenuItems }
    }

    private var iconColor: Color {
        switch file.type {
        case .local: return .dnsAccent
        case .remote: return .dnsWarning
        case .combined: return .quad9Purple
        }
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        if file.type == .local {
            Button {
                hostsManager.duplicateFile(file)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
        }

        if file.type == .remote {
            Button {
                Task { await RemoteSyncService.shared.syncFile(file) }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }

        if !file.isOriginal {
            Divider()
            Button(role: .destructive) {
                hostsManager.deleteFile(file)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
