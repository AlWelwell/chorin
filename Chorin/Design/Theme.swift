import SwiftUI

enum ChorinTheme {
    // MARK: - Colors (Dark Leather + Coral Pastel)
    static let background     = Color(hex: "161110")
    static let surface        = Color(hex: "231C19")
    static let surfaceBorder  = Color(hex: "362B26")
    static let surfaceRaised  = Color(hex: "2D2420")
    static let tertiary       = Color(hex: "3A2A24")

    static let primary        = Color(hex: "FF9080")  // Coral
    static let primarySoft    = Color(hex: "FFAB9E")
    static let primaryPressed = Color(hex: "E87868")
    static let secondary      = Color(hex: "FFC4B5")  // Peach

    static let success        = Color(hex: "9FD4B2")  // Sage green
    static let successSoft    = Color(hex: "9FD4B2").opacity(0.12)
    static let warning        = Color(hex: "F5D49A")
    static let danger         = Color(hex: "F08080")

    static let textPrimary    = Color(hex: "F5EAE4")
    static let textSecondary  = Color(hex: "BFB0A8")
    static let textMuted      = Color(hex: "7A6C64")

    // MARK: - Spacing
    static let radiusXS: CGFloat = 6
    static let radiusSM: CGFloat = 10
    static let radius: CGFloat = 16
    static let radiusLG: CGFloat = 20

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, primarySoft],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let progressGradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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
