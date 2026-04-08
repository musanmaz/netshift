import SwiftUI

struct HostsFileRow: View {
    let file: HostsFile
    let isActive: Bool

    @EnvironmentObject var hostsManager: HostsFileManager

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            activateButton

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
        }
        .padding(.vertical, 2)
        .contextMenu { contextMenuItems }
    }

    private var activateButton: some View {
        Button {
            if !isActive {
                try? hostsManager.activateFile(file)
            }
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(isActive ? Color.dnsSuccess : Color.secondary.opacity(0.4), lineWidth: isActive ? 0 : 1.5)
                    .frame(width: 18, height: 18)

                if isActive {
                    Circle()
                        .fill(Color.dnsSuccess)
                        .frame(width: 18, height: 18)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .help(isActive ? "Active" : "Activate")
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
