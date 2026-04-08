import SwiftUI

struct DNSProfile: Identifiable, Equatable {
    let id: String
    let name: String
    let primaryDNS: String
    let secondaryDNS: String
    let description: String
    let sfSymbol: String
    let brandColor: Color
    var isActive: Bool
    var lastBenchmarkMS: Double?

    var servers: [String] {
        [primaryDNS, secondaryDNS]
    }

    var latencyRating: LatencyRating? {
        guard let ms = lastBenchmarkMS else { return nil }
        return LatencyRating.from(ms: ms)
    }
}

enum LatencyRating: String {
    case excellent = "Excellent"
    case good = "Good"
    case moderate = "Moderate"
    case slow = "Slow"

    var color: Color {
        switch self {
        case .excellent: return .dnsSuccess
        case .good: return .dnsAccent
        case .moderate: return .dnsWarning
        case .slow: return .dnsDanger
        }
    }

    var sfSymbol: String {
        switch self {
        case .excellent: return "bolt.fill"
        case .good: return "checkmark.circle.fill"
        case .moderate: return "minus.circle.fill"
        case .slow: return "exclamationmark.triangle.fill"
        }
    }

    static func from(ms: Double) -> LatencyRating {
        switch ms {
        case ..<20: return .excellent
        case ..<50: return .good
        case ..<100: return .moderate
        default: return .slow
        }
    }
}

extension DNSProfile {
    static let builtIn: [DNSProfile] = [
        DNSProfile(
            id: "cloudflare",
            name: "Cloudflare",
            primaryDNS: "1.1.1.1",
            secondaryDNS: "1.0.0.1",
            description: "Fast, privacy-focused DNS",
            sfSymbol: "shield.checkered",
            brandColor: .cloudflareOrange,
            isActive: false
        ),
        DNSProfile(
            id: "google",
            name: "Google",
            primaryDNS: "8.8.8.8",
            secondaryDNS: "8.8.4.4",
            description: "Google Public DNS",
            sfSymbol: "magnifyingglass",
            brandColor: .googleBlue,
            isActive: false
        ),
        DNSProfile(
            id: "quad9",
            name: "Quad9",
            primaryDNS: "9.9.9.9",
            secondaryDNS: "149.112.112.112",
            description: "Security-focused DNS",
            sfSymbol: "lock.shield",
            brandColor: .quad9Purple,
            isActive: false
        ),
        DNSProfile(
            id: "opendns",
            name: "OpenDNS",
            primaryDNS: "208.67.222.222",
            secondaryDNS: "208.67.220.220",
            description: "Cisco OpenDNS",
            sfSymbol: "globe",
            brandColor: .opendnsYellow,
            isActive: false
        ),
    ]
}
