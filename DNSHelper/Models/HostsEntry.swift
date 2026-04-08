import Foundation

struct HostsEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var ipAddress: String
    var hostnames: [String]
    var comment: String?
    var isEnabled: Bool

    init(id: UUID = UUID(), ipAddress: String, hostnames: [String], comment: String? = nil, isEnabled: Bool = true) {
        self.id = id
        self.ipAddress = ipAddress
        self.hostnames = hostnames
        self.comment = comment
        self.isEnabled = isEnabled
    }

    var lineRepresentation: String {
        let base = "\(ipAddress)\t\(hostnames.joined(separator: " "))"
        let withComment = comment.map { "\(base) # \($0)" } ?? base
        return isEnabled ? withComment : "# \(withComment)"
    }

    static func parse(line: String) -> HostsEntry? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        var isEnabled = true
        var workingLine = trimmed

        if workingLine.hasPrefix("#") {
            let uncommented = String(workingLine.dropFirst()).trimmingCharacters(in: .whitespaces)
            let parts = uncommented.split(separator: " ", maxSplits: 1).first.map(String.init) ?? ""
            if isValidIP(parts) {
                isEnabled = false
                workingLine = uncommented
            } else {
                return nil
            }
        }

        var inlineComment: String?
        if let hashIndex = workingLine.range(of: " #") {
            inlineComment = String(workingLine[hashIndex.upperBound...]).trimmingCharacters(in: .whitespaces)
            workingLine = String(workingLine[..<hashIndex.lowerBound])
        }

        let components = workingLine.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard components.count >= 2, isValidIP(components[0]) else { return nil }

        return HostsEntry(
            ipAddress: components[0],
            hostnames: Array(components[1...]),
            comment: inlineComment,
            isEnabled: isEnabled
        )
    }

    private static func isValidIP(_ string: String) -> Bool {
        let ipv4 = string.split(separator: ".").count == 4
            && string.split(separator: ".").allSatisfy { Int($0) != nil }
        let ipv6 = string.contains(":")
        return ipv4 || ipv6
    }
}
