import SwiftUI

struct HostsEditorView: View {
    @Binding var file: HostsFile
    @EnvironmentObject var settings: AppSettings
    @State private var showSaveConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            Divider()
            editorBody
            Divider()
            editorFooter
        }
    }

    // MARK: - Header

    private var editorHeader: some View {
        HStack {
            Image(systemName: file.type.sfSymbol)
                .foregroundStyle(.secondary)
            Text(file.name)
                .font(.headline)

            if file.isActive {
                Text("ACTIVE")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.dnsSuccess.opacity(0.15)))
                    .foregroundStyle(Color.dnsSuccess)
            }

            Spacer()

            if file.type == .remote, let url = file.remoteURL {
                Link(destination: URL(string: url)!) {
                    Label("View Source", systemImage: "arrow.up.right.square")
                        .font(.caption)
                }
            }

            Text("Last updated: ")
                .font(.caption)
                .foregroundStyle(.tertiary)
            + Text(file.lastUpdated, style: .relative)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(.bar)
    }

    // MARK: - Editor Body

    @ViewBuilder
    private var editorBody: some View {
        if file.isEditable {
            HostsCodeEditor(
                text: $file.content,
                isEditable: true,
                fontSize: settings.editorFontSize,
                showLineNumbers: settings.showLineNumbers
            )
            .overlay(alignment: .topTrailing) {
                if showSaveConfirmation {
                    Text("Saved")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.dnsSuccess.opacity(0.2)))
                        .foregroundStyle(Color.dnsSuccess)
                        .padding(DesignTokens.Spacing.md)
                        .transition(.opacity)
                }
            }
        } else {
            HostsCodeEditor(
                text: .constant(file.content),
                isEditable: false,
                fontSize: settings.editorFontSize,
                showLineNumbers: settings.showLineNumbers
            )
            .overlay(alignment: .topTrailing) {
                Label("Read Only", systemImage: "lock.fill")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.quaternary))
                    .foregroundStyle(.secondary)
                    .padding(DesignTokens.Spacing.md)
            }
        }
    }

    // MARK: - Footer

    private var editorFooter: some View {
        HStack {
            Text("\(file.lineCount) lines")
                .font(.editorLineNumber)
                .foregroundStyle(.secondary)

            Divider().frame(height: 12)

            Text(file.fileSize)
                .font(.editorLineNumber)
                .foregroundStyle(.secondary)

            Divider().frame(height: 12)

            Text("UTF-8")
                .font(.editorLineNumber)
                .foregroundStyle(.tertiary)

            Spacer()

            Text("\(file.entries.count) host entries")
                .font(.editorLineNumber)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(.bar)
    }
}
