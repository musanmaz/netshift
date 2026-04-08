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

    func activateFile(_ file: HostsFile) throws {
        var content = file.content

        if file.type == .combined {
            content = buildCombinedContent(file)
        }

        try PrivilegedHelper.shared.writeHostsFile(content: content)

        for i in files.indices {
            files[i].isActive = (files[i].id == file.id)
        }
        saveConfig()
        logger.info("File activated: \(file.name)")
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
        guard let content = try? String(contentsOfFile: "/etc/hosts", encoding: .utf8) else { return }
        if let idx = files.firstIndex(where: { $0.isActive }) {
            files[idx].content = content
            files[idx].lastUpdated = Date()
        }
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
