import Foundation
import Combine

struct NetworkService: Identifiable, Equatable {
    let id: String
    let name: String
    var dnsServers: [String]
}

final class DNSManager: ObservableObject {
    static let shared = DNSManager()

    @Published var profiles: [DNSProfile] = DNSProfile.builtIn
    @Published var networkServices: [NetworkService] = []
    @Published var isApplying = false

    private let logger = AppLogger.shared
    private let helper = PrivilegedHelper.shared

    private init() {
        refreshStatus()
    }

    // MARK: - Network Services

    func listServices() throws -> [String] {
        let output = try shellOutput("networksetup", "-listallnetworkservices")
        return output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("An asterisk") }
    }

    // MARK: - Switch DNS

    func applyProfile(_ profile: DNSProfile) throws {
        isApplying = true
        defer { isApplying = false }

        let services = try listServices()
        logger.info("Switching DNS: \(profile.name) (\(profile.servers.joined(separator: ", ")))")

        for service in services {
            try helper.setDNS(service: service, servers: profile.servers)
        }

        try helper.flushDNSCache()

        for i in profiles.indices {
            profiles[i].isActive = (profiles[i].id == profile.id)
        }

        logger.info("DNS switched to: \(profile.name)")
    }

    func applyCustomDNS(primary: String, secondary: String) throws {
        isApplying = true
        defer { isApplying = false }

        let services = try listServices()
        for service in services {
            try helper.setDNS(service: service, servers: [primary, secondary])
        }

        try helper.flushDNSCache()

        for i in profiles.indices {
            profiles[i].isActive = false
        }

        logger.info("Custom DNS applied: \(primary), \(secondary)")
    }

    // MARK: - Reset

    func resetToDHCP() throws {
        isApplying = true
        defer { isApplying = false }

        let services = try listServices()
        for service in services {
            try helper.resetDNS(service: service)
        }

        try helper.flushDNSCache()

        for i in profiles.indices {
            profiles[i].isActive = false
        }

        logger.info("DNS reset to DHCP default")
    }

    // MARK: - Status

    func refreshStatus() {
        Task {
            do {
                let services = try listServices()
                var results: [NetworkService] = []

                for service in services {
                    let output = try shellOutput("networksetup", "-getdnsservers", service)
                    let servers: [String]
                    if output.contains("There aren't any DNS Servers set") {
                        servers = []
                    } else {
                        servers = output
                            .components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                    }
                    results.append(NetworkService(id: service, name: service, dnsServers: servers))
                }

                await MainActor.run {
                    self.networkServices = results
                    self.detectActiveProfile()
                }
            } catch {
                logger.error("Failed to read DNS status: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private

    private func detectActiveProfile() {
        let currentServers = Set(networkServices.flatMap(\.dnsServers))
        for i in profiles.indices {
            profiles[i].isActive = currentServers == Set(profiles[i].servers)
        }
    }

    private func shellOutput(_ args: String...) throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
