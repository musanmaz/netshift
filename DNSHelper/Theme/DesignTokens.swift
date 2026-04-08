import SwiftUI

enum DesignTokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum CornerRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let card: CGFloat = 12
    }

    enum Shadow {
        static let cardColor = Color.black.opacity(0.05)
        static let cardRadius: CGFloat = 4
        static let cardY: CGFloat = 2

        static let popoverColor = Color.black.opacity(0.12)
        static let popoverRadius: CGFloat = 12
        static let popoverY: CGFloat = 4
    }

    enum IconSize {
        static let sm: CGFloat = 14
        static let md: CGFloat = 18
        static let lg: CGFloat = 24
        static let xl: CGFloat = 36
        static let emptyState: CGFloat = 48
    }

    enum WindowSize {
        static let editorDefault = CGSize(width: 900, height: 600)
        static let editorMinimum = CGSize(width: 700, height: 450)
        static let preferences = CGSize(width: 480, height: 320)
        static let onboarding = CGSize(width: 500, height: 400)
        static let sidebarWidth: CGFloat = 220
    }
}
