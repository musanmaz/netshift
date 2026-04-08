import SwiftUI

extension Font {
    static let editorFont = Font.system(.body, design: .monospaced)
    static let editorLineNumber = Font.system(.caption, design: .monospaced).monospacedDigit()
    static let ipAddress = Font.system(.body, design: .monospaced).monospacedDigit()
    static let latencyValue = Font.system(.caption, design: .monospaced).monospacedDigit()
    static let sectionHeader = Font.system(.caption).weight(.semibold)
    static let cardTitle = Font.system(.headline)
    static let cardSubtitle = Font.system(.subheadline)
    static let statusBarLabel = Font.system(.caption2)
    static let benchmarkValue = Font.system(.title2, design: .monospaced).monospacedDigit()
}
