import SwiftUI
import AppKit

extension Color {
    // MARK: - Accent & Status
    static let dnsAccent = Color.accentColor
    static let dnsSuccess = Color(nsColor: .systemGreen)
    static let dnsWarning = Color(nsColor: .systemOrange)
    static let dnsDanger = Color(nsColor: .systemRed)

    // MARK: - Backgrounds
    static let dnsSidebarBg = Color(nsColor: .controlBackgroundColor)
    static let dnsEditorBg = Color(nsColor: .textBackgroundColor)
    static let dnsCardBg = Color(nsColor: .windowBackgroundColor)

    // MARK: - DNS Profile Brand Colors
    static let cloudflareOrange = Color(red: 0.957, green: 0.506, blue: 0.125)
    static let googleBlue = Color(red: 0.259, green: 0.522, blue: 0.957)
    static let quad9Purple = Color(red: 0.424, green: 0.247, blue: 0.667)
    static let opendnsYellow = Color(red: 1.0, green: 0.757, blue: 0.027)

    // MARK: - Editor Syntax
    static let syntaxComment = Color(nsColor: .systemGray)
    static let syntaxIP = Color(nsColor: .systemBlue)
    static let syntaxLocalhost = Color(nsColor: .systemGreen).opacity(0.15)
    static let syntaxError = Color(nsColor: .systemRed)

    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
