import SwiftUI

struct ChorinButton: View {
    let title: String
    var style: Style = .primary
    var isLoading: Bool = false
    let action: () -> Void

    enum Style {
        case primary, secondary, outline, danger
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(style == .primary ? Color(hex: "161110") : ChorinTheme.primary)
                } else {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: style == .outline ? 1.5 : 0)
            )
        }
        .disabled(isLoading)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: ChorinTheme.primary
        case .secondary: ChorinTheme.tertiary
        case .outline: .clear
        case .danger: ChorinTheme.danger.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: Color(hex: "161110")
        case .secondary: ChorinTheme.primary
        case .outline: ChorinTheme.textSecondary
        case .danger: ChorinTheme.danger
        }
    }

    private var borderColor: Color {
        style == .outline ? ChorinTheme.surfaceBorder : .clear
    }
}
