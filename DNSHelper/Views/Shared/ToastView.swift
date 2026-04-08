import SwiftUI

enum ToastStyle {
    case success, warning, error, info

    var color: Color {
        switch self {
        case .success: return .dnsSuccess
        case .warning: return .dnsWarning
        case .error: return .dnsDanger
        case .info: return .dnsAccent
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct ToastData: Equatable {
    let message: String
    let style: ToastStyle

    static func == (lhs: ToastData, rhs: ToastData) -> Bool {
        lhs.message == rhs.message
    }
}

struct ToastView: View {
    let data: ToastData

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: data.style.icon)
                .foregroundStyle(data.style.color)
                .font(.system(size: DesignTokens.IconSize.md))

            Text(data.message)
                .font(.callout)
                .lineLimit(2)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .fill(.regularMaterial)
                .shadow(
                    color: DesignTokens.Shadow.popoverColor,
                    radius: DesignTokens.Shadow.popoverRadius,
                    y: DesignTokens.Shadow.popoverY
                )
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastData?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast {
                ToastView(data: toast)
                    .padding(.top, DesignTokens.Spacing.lg)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                self.toast = nil
                            }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toast)
    }
}

extension View {
    func toast(_ data: Binding<ToastData?>) -> some View {
        modifier(ToastModifier(toast: data))
    }
}
