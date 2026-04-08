import SwiftUI

struct HostsFileListView: View {
    @EnvironmentObject var hostsManager: HostsFileManager

    var body: some View {
        List(selection: $hostsManager.selectedFileID) {
            if !hostsManager.localFiles.isEmpty {
                Section {
                    ForEach(hostsManager.localFiles) { file in
                        HostsFileRow(file: file, isActive: file.isActive)
                            .tag(file.id)
                    }
                } header: {
                    sectionHeader("LOCAL", icon: "doc.text")
                }
            }

            if !hostsManager.remoteFiles.isEmpty {
                Section {
                    ForEach(hostsManager.remoteFiles) { file in
                        HostsFileRow(file: file, isActive: file.isActive)
                            .tag(file.id)
                    }
                } header: {
                    sectionHeader("REMOTE", icon: "cloud.fill")
                }
            }

            if !hostsManager.combinedFiles.isEmpty {
                Section {
                    ForEach(hostsManager.combinedFiles) { file in
                        HostsFileRow(file: file, isActive: file.isActive)
                            .tag(file.id)
                    }
                } header: {
                    sectionHeader("COMBINED", icon: "square.stack.3d.up.fill")
                }
            }

            if hostsManager.files.isEmpty {
                EmptyStateView(
                    icon: "doc.text.magnifyingglass",
                    title: "No Files Yet",
                    message: "Click the + button to create a new hosts file."
                )
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
