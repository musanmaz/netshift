import Foundation
import Combine

final class FileMonitor: ObservableObject {
    @Published var lastChangeDate: Date?

    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let path: String
    private let logger = AppLogger.shared

    init(path: String = "/etc/hosts") {
        self.path = path
    }

    func startMonitoring() {
        stopMonitoring()

        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            logger.error("Failed to start file monitoring: \(path)")
            return
        }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        source?.setEventHandler { [weak self] in
            guard let self else { return }
            self.lastChangeDate = Date()
            self.logger.info("Change detected in \(self.path)")
        }

        source?.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }

        source?.resume()
        logger.info("Monitoring started for \(path)")
    }

    func stopMonitoring() {
        source?.cancel()
        source = nil
    }

    deinit {
        stopMonitoring()
    }
}
