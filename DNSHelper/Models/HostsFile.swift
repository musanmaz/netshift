import Foundation

enum HostsFileType: String, Codable, CaseIterable {
    case local
    case remote
    case combined

    var label: String {
        switch self {
        case .local: return "Local"
        case .remote: return "Remote"
        case .combined: return "Combined"
        }
    }

    var sfSymbol: String {
        switch self {
        case .local: return "doc.text"
        case .remote: return "cloud.fill"
        case .combined: return "square.stack.3d.up.fill"
        }
    }
}

struct HostsFile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var type: HostsFileType
    var isActive: Bool
    var content: String
    var remoteURL: String?
    var childFileIDs: [UUID]?
    var lastUpdated: Date
    var isOriginal: Bool

    init(
        id: UUID = UUID(),
        name: String,
        type: HostsFileType,
        isActive: Bool = false,
        content: String = "",
        remoteURL: String? = nil,
        childFileIDs: [UUID]? = nil,
        lastUpdated: Date = Date(),
        isOriginal: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isActive = isActive
        self.content = content
        self.remoteURL = remoteURL
        self.childFileIDs = childFileIDs
        self.lastUpdated = lastUpdated
        self.isOriginal = isOriginal
    }

    var isEditable: Bool {
        type == .local && !isOriginal
    }

    var lineCount: Int {
        content.components(separatedBy: .newlines).count
    }

    var fileSize: String {
        let bytes = content.utf8.count
        if bytes < 1024 {
            return "\(bytes) B"
        } else {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        }
    }

    var entries: [HostsEntry] {
        content.components(separatedBy: .newlines).compactMap { HostsEntry.parse(line: $0) }
    }
}
