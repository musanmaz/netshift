import SwiftUI

enum EditorTab: String, CaseIterable {
    case hosts = "Hosts"
    case dns = "DNS"

    var icon: String {
        switch self {
        case .hosts: return "doc.text"
        case .dns: return "antenna.radiowaves.left.and.right"
        }
    }
}

struct MainEditorView: View {
    @EnvironmentObject var hostsManager: HostsFileManager
    @EnvironmentObject var dnsManager: DNSManager
    @EnvironmentObject var settings: AppSettings

    @State private var selectedTab: EditorTab = .hosts
    @State private var toast: ToastData?
    @State private var showCreateSheet = false
    @State private var showDeleteAlert = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar { toolbarContent }
        .toast($toast)
        .sheet(isPresented: $showCreateSheet) {
            CreateFileSheet { name, type, url in
                hostsManager.createFile(name: name, type: type, remoteURL: url)
                showToast("'\(name)' created", style: .success)
            }
        }
        .alert("Delete File", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let file = hostsManager.selectedFile {
                    hostsManager.deleteFile(file)
                    showToast("'\(file.name)' deleted", style: .info)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to permanently delete this file?")
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(EditorTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(DesignTokens.Spacing.md)

            Divider()

            switch selectedTab {
            case .hosts:
                HostsFileListView()
            case .dns:
                DNSProfileListView()
            }
        }
        .frame(minWidth: DesignTokens.WindowSize.sidebarWidth)
        .listStyle(.sidebar)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .hosts:
            if let file = hostsManager.selectedFile {
                HostsEditorView(file: binding(for: file))
            } else {
                EmptyStateView(
                    icon: "doc.text.magnifyingglass",
                    title: "No File Selected",
                    message: "Select a hosts file from the sidebar to edit, or create a new one.",
                    actionLabel: "New File",
                    action: { showCreateSheet = true }
                )
            }
        case .dns:
            DNSStatusView()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if selectedTab == .hosts {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("Create", systemImage: "plus")
                }
                .help("Create new hosts file")
                .keyboardShortcut("n", modifiers: .command)

                Button {
                    guard hostsManager.selectedFile != nil,
                          hostsManager.selectedFile?.isOriginal != true else { return }
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .help("Delete selected file")
                .disabled(hostsManager.selectedFile == nil || hostsManager.selectedFile?.isOriginal == true)

                Button {
                    activateSelected()
                } label: {
                    Label("Activate", systemImage: "checkmark.circle")
                }
                .help("Activate selected file as /etc/hosts")
                .keyboardShortcut("a", modifiers: [.command, .shift])
                .disabled(hostsManager.selectedFile == nil)
            }

            if selectedTab == .dns {
                Button {
                    dnsManager.refreshStatus()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Refresh DNS status")
            }
        }
    }

    // MARK: - Actions

    private func activateSelected() {
        guard let file = hostsManager.selectedFile else { return }
        do {
            try hostsManager.activateFile(file)
            showToast("'\(file.name)' activated", style: .success)
        } catch {
            showToast("Activation error: \(error.localizedDescription)", style: .error)
        }
    }

    private func showToast(_ message: String, style: ToastStyle) {
        withAnimation { toast = ToastData(message: message, style: style) }
    }

    private func binding(for file: HostsFile) -> Binding<HostsFile> {
        Binding(
            get: { hostsManager.selectedFile ?? file },
            set: { hostsManager.selectedFile = $0 }
        )
    }
}

// MARK: - Create File Sheet

struct CreateFileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type: HostsFileType = .local
    @State private var remoteURL = ""

    var onCreate: (String, HostsFileType, String?) -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Text("New Hosts File")
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                TextField("File Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                Picker("Type", selection: $type) {
                    ForEach(HostsFileType.allCases, id: \.self) { t in
                        Label(t.label, systemImage: t.sfSymbol).tag(t)
                    }
                }

                if type == .remote {
                    TextField("Remote URL", text: $remoteURL)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Create") {
                    let url = type == .remote ? remoteURL : nil
                    onCreate(name, type, url)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || (type == .remote && remoteURL.isEmpty))
                .keyboardShortcut(.return)
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(width: 400)
    }
}
