import Foundation
import Combine

final class HostsFileManager: ObservableObject {
    static let shared = HostsFileManager()

    @Published var files: [HostsFile] = []
    @Published var selectedFileID: UUID?

    let fileMonitor = FileMonitor()

    private let storageDir: URL
    private let configURL: URL
    private let logger = AppLogger.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        storageDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/NetShift")
        configURL = storageDir.appendingPathComponent("hosts_config.json")

        ensureStorageDirectory()
        loadConfig()
        ensureOriginalFile()

        fileMonitor.startMonitoring()
        fileMonitor.$lastChangeDate
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.refreshActiveFileContent() }
            .store(in: &cancellables)
    }

    // MARK: - CRUD

    func createFile(name: String, type: HostsFileType, remoteURL: String? = nil) {
        let file = HostsFile(
            name: name,
            type: type,
            content: type == .local ? defaultHostsContent() : "",
            remoteURL: remoteURL,
            childFileIDs: type == .combined ? [] : nil
        )
        files.append(file)
        selectedFileID = file.id
        saveConfig()
        logger.info("File created: \(name) (\(type.rawValue))")
    }

    func deleteFile(_ file: HostsFile) {
        guard !file.isOriginal else { return }
        files.removeAll { $0.id == file.id }
        if selectedFileID == file.id {
            selectedFileID = files.first?.id
        }
        saveConfig()
        logger.info("File deleted: \(file.name)")
    }

    func updateFile(_ file: HostsFile) {
        guard let index = files.firstIndex(where: { $0.id == file.id }) else { return }
        files[index] = file
        saveConfig()
    }

    /// Activates a single file as the *only* active one (replaces the active set).
    func activateFile(_ file: HostsFile) throws {
        let previous = files.map(\.isActive)
        for i in files.indices {
            files[i].isActive = (files[i].id == file.id)
        }
        do {
            try rebuildSystemHosts()
        } catch {
            for i in files.indices { files[i].isActive = previous[i] }
            throw error
        }
        saveConfig()
        logger.info("File activated: \(file.name)")
    }

    /// Toggles a file's active state on/off. Multiple files can be active at once;
    /// the system `/etc/hosts` is rebuilt from the merge of all active files.
    func toggleActive(_ file: HostsFile) throws {
        try setActive(file, !file.isActive)
    }

    /// Sets a single file's active state without affecting others, then rebuilds `/etc/hosts`.
    func setActive(_ file: HostsFile, _ active: Bool) throws {
        guard let index = files.firstIndex(where: { $0.id == file.id }),
              files[index].isActive != active else { return }

        files[index].isActive = active
        do {
            try rebuildSystemHosts()
        } catch {
            files[index].isActive = !active
            throw error
        }
        saveConfig()
        logger.info("File \(active ? "activated" : "deactivated"): \(file.name)")
    }

    func duplicateFile(_ file: HostsFile) {
        var copy = file
        copy = HostsFile(
            name: "\(file.name) Copy",
            type: .local,
            content: file.content
        )
        files.append(copy)
        selectedFileID = copy.id
        saveConfig()
    }

    var selectedFile: HostsFile? {
        get { files.first { $0.id == selectedFileID } }
        set {
            if let newValue, let idx = files.firstIndex(where: { $0.id == newValue.id }) {
                files[idx] = newValue
                saveConfig()
            }
        }
    }

    var activeFile: HostsFile? {
        files.first { $0.isActive }
    }

    var activeFiles: [HostsFile] {
        files.filter { $0.isActive }
    }

    var localFiles: [HostsFile] { files.filter { $0.type == .local } }
    var remoteFiles: [HostsFile] { files.filter { $0.type == .remote } }
    var combinedFiles: [HostsFile] { files.filter { $0.type == .combined } }

    // MARK: - Persistence

    private func saveConfig() {
        do {
            let data = try JSONEncoder().encode(files)
            try data.write(to: configURL, options: .atomic)
        } catch {
            logger.error("Failed to save config: \(error.localizedDescription)")
        }
    }

    private func loadConfig() {
        guard FileManager.default.fileExists(atPath: configURL.path) else { return }
        do {
            let data = try Data(contentsOf: configURL)
            files = try JSONDecoder().decode([HostsFile].self, from: data)
            selectedFileID = files.first?.id
        } catch {
            logger.error("Failed to load config: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func ensureStorageDirectory() {
        try? FileManager.default.createDirectory(at: storageDir, withIntermediateDirectories: true)
    }

    private func ensureOriginalFile() {
        guard !files.contains(where: { $0.isOriginal }) else { return }

        let content = (try? String(contentsOfFile: "/etc/hosts", encoding: .utf8)) ?? ""
        let original = HostsFile(
            name: "Original",
            type: .local,
            isActive: true,
            content: content,
            isOriginal: true
        )
        files.insert(original, at: 0)
        selectedFileID = original.id
        saveConfig()
        logger.info("Original hosts file copied")
    }

    private func refreshActiveFileContent() {
        // Only mirror external `/etc/hosts` edits back into a file when exactly one
        // simple file is active. When multiple files are merged we can't attribute
        // the system content to a single source file, so we skip the reverse-sync.
        let active = files.filter { $0.isActive }
        guard active.count == 1, let only = active.first, only.type != .combined,
              let content = try? String(contentsOfFile: "/etc/hosts", encoding: .utf8),
              let idx = files.firstIndex(where: { $0.id == only.id }) else { return }
        files[idx].content = content
        files[idx].lastUpdated = Date()
    }

    // MARK: - System hosts rebuild

    /// Rebuilds `/etc/hosts` from the full set of currently active files.
    private func rebuildSystemHosts() throws {
        let active = orderedActiveFiles()
        let content: String

        if active.isEmpty {
            content = defaultHostsContent()
        } else if active.count == 1 {
            let file = active[0]
            content = file.type == .combined ? buildCombinedContent(file) : file.content
        } else {
            content = buildMergedContent(active)
        }

        try PrivilegedHelper.shared.writeHostsFile(content: content)
    }

    /// Active files with the Original (system base) first, so localhost entries stay on top.
    private func orderedActiveFiles() -> [HostsFile] {
        let active = files.filter { $0.isActive }
        return active.filter { $0.isOriginal } + active.filter { !$0.isOriginal }
    }

    /// Concatenates the content of multiple active files into a single hosts file,
    /// expanding combined files into their child contents.
    private func buildMergedContent(_ active: [HostsFile]) -> String {
        var merged = "# NetShift merged hosts file (\(active.count) profiles active)\n"
        merged += "# Generated by NetShift on \(Date())\n\n"

        for file in active {
            let body = file.type == .combined ? buildCombinedContent(file) : file.content
            merged += "# ===== \(file.name) =====\n"
            merged += body
            if !body.hasSuffix("\n") { merged += "\n" }
            merged += "\n"
        }
        return merged
    }

    private func buildCombinedContent(_ file: HostsFile) -> String {
        guard let childIDs = file.childFileIDs else { return "" }
        var combined = "# Combined hosts file: \(file.name)\n"
        combined += "# Generated by NetShift on \(Date())\n\n"

        for childID in childIDs {
            guard let child = files.first(where: { $0.id == childID }) else { continue }
            combined += "# --- \(child.name) ---\n"
            combined += child.content
            combined += "\n\n"
        }
        return combined
    }

    private func defaultHostsContent() -> String {
        """
        ##
        # Host Database
        #
        # localhost is used to configure the loopback interface
        # when the system is booting. Do not change this entry.
        ##
        127.0.0.1\tlocalhost
        255.255.255.255\tbroadcasthost
        ::1\t\t\tlocalhost
        """
    }
}
