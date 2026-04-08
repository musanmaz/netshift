import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.IconSize.emptyState))
                .foregroundStyle(.secondary.opacity(0.6))
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.medium)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            if let actionLabel, let action {
                Button(action: action) {
                    Label(actionLabel, systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignTokens.Spacing.xxl)
    }
}
