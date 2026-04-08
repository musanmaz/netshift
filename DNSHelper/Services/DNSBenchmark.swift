import Foundation
import Network
import Combine

struct BenchmarkResult: Identifiable {
    let id: String
    let profileName: String
    let brandColor: String
    var latencies: [TimeInterval]
    var successes: Int
    var total: Int

    var avgMS: Double {
        guard !latencies.isEmpty else { return 0 }
        return latencies.reduce(0, +) / Double(latencies.count) * 1000
    }

    var p50MS: Double { percentile(0.50) }
    var p90MS: Double { percentile(0.90) }
    var successRate: Double { total > 0 ? Double(successes) / Double(total) * 100 : 0 }

    private func percentile(_ p: Double) -> Double {
        guard !latencies.isEmpty else { return 0 }
        let sorted = latencies.sorted()
        let idx = Int(Double(sorted.count - 1) * p)
        return sorted[idx] * 1000
    }
}

final class DNSBenchmark: ObservableObject {
    @Published var results: [BenchmarkResult] = []
    @Published var isRunning = false
    @Published var progress: Double = 0
    @Published var currentProfile: String = ""

    private let logger = AppLogger.shared

    let defaultDomains = ["google.com", "cloudflare.com", "github.com"]
    let defaultRuns = 5
    let defaultTimeout: TimeInterval = 1.5

    func runBenchmark(
        profiles: [DNSProfile],
        domains: [String]? = nil,
        runs: Int? = nil,
        timeout: TimeInterval? = nil
    ) async {
        let testDomains = domains ?? defaultDomains
        let testRuns = runs ?? defaultRuns
        let testTimeout = timeout ?? defaultTimeout

        await MainActor.run {
            self.isRunning = true
            self.progress = 0
            self.results = []
        }

        let totalOperations = Double(profiles.count * testDomains.count * testRuns)
        var completedOps: Double = 0

        var allResults: [BenchmarkResult] = []

        for profile in profiles {
            await MainActor.run { self.currentProfile = profile.name }

            var result = BenchmarkResult(
                id: profile.id,
                profileName: profile.name,
                brandColor: profile.id,
                latencies: [],
                successes: 0,
                total: 0
            )

            for domain in testDomains {
                for _ in 0..<testRuns {
                    let start = Date()
                    let success = await resolveDNS(
                        server: profile.primaryDNS,
                        domain: domain,
                        timeout: testTimeout
                    )
                    let elapsed = Date().timeIntervalSince(start)

                    result.total += 1
                    if success {
                        result.successes += 1
                        result.latencies.append(elapsed)
                    }

                    completedOps += 1
                    await MainActor.run {
                        self.progress = completedOps / totalOperations
                    }
                }
            }

            allResults.append(result)
            await MainActor.run {
                self.results = allResults
            }
        }

        await MainActor.run {
            self.isRunning = false
            self.progress = 1.0
            self.currentProfile = ""
        }

        logger.info("Benchmark completed: \(profiles.count) profile(s) tested")
    }

    private func resolveDNS(server: String, domain: String, timeout: TimeInterval) async -> Bool {
        await withCheckedContinuation { continuation in
            let endpoint = NWEndpoint.hostPort(
                host: NWEndpoint.Host(server),
                port: NWEndpoint.Port(integerLiteral: 53)
            )
            let params = NWParameters.udp
            let connection = NWConnection(to: endpoint, using: params)

            let timer = DispatchSource.makeTimerSource(queue: .global())
            timer.schedule(deadline: .now() + timeout)
            timer.setEventHandler {
                connection.cancel()
                continuation.resume(returning: false)
            }
            timer.resume()

            let query = buildDNSQuery(for: domain)
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.send(content: query, completion: .contentProcessed { _ in
                        connection.receive(minimumIncompleteLength: 1, maximumLength: 65535) { data, _, _, _ in
                            timer.cancel()
                            connection.cancel()
                            continuation.resume(returning: data != nil)
                        }
                    })
                case .failed, .cancelled:
                    timer.cancel()
                    break
                default:
                    break
                }
            }
            connection.start(queue: .global())
        }
    }

    private func buildDNSQuery(for domain: String) -> Data {
        var data = Data()
        // Transaction ID
        data.append(contentsOf: [0x00, 0x01])
        // Flags: standard query
        data.append(contentsOf: [0x01, 0x00])
        // Questions: 1
        data.append(contentsOf: [0x00, 0x01])
        // Answer, Authority, Additional RRs: 0
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00])

        for label in domain.split(separator: ".") {
            data.append(UInt8(label.count))
            data.append(contentsOf: label.utf8)
        }
        data.append(0x00)

        // Type A, Class IN
        data.append(contentsOf: [0x00, 0x01, 0x00, 0x01])
        return data
    }
}
