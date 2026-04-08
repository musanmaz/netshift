import Foundation
import Combine

final class RemoteSyncService: ObservableObject {
    static let shared = RemoteSyncService()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    private var timer: AnyCancellable?
    private let logger = AppLogger.shared
    private let settings = AppSettings.shared

    private init() {
        scheduleSync()
    }

    func scheduleSync() {
        timer?.cancel()
        guard let interval = settings.remoteSyncInterval.seconds else { return }

        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.syncAllRemoteFiles() }
            }
    }

    func syncAllRemoteFiles() async {
        let hostsManager = HostsFileManager.shared
        let remoteFiles = hostsManager.remoteFiles

        guard !remoteFiles.isEmpty else { return }

        await MainActor.run { isSyncing = true }
        defer { Task { @MainActor in isSyncing = false } }

        logger.info("Remote file sync starting: \(remoteFiles.count) file(s)")

        for file in remoteFiles {
            await syncFile(file)
        }

        await MainActor.run { lastSyncDate = Date() }
        logger.info("Remote file sync completed")
    }

    func syncFile(_ file: HostsFile) async {
        guard let urlString = file.remoteURL, let url = URL(string: urlString) else {
            logger.warning("Invalid remote URL: \(file.name)")
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                logger.warning("Failed to download remote file: \(file.name) (HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0))")
                return
            }

            guard let content = String(data: data, encoding: .utf8) else {
                logger.warning("Failed to decode remote file: \(file.name)")
                return
            }

            var updated = file
            updated.content = content
            updated.lastUpdated = Date()
            HostsFileManager.shared.updateFile(updated)

            logger.info("Remote file updated: \(file.name)")
        } catch {
            logger.error("Remote file download error: \(file.name) - \(error.localizedDescription)")
        }
    }
}
