import SwiftUI

struct ChorinCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(ChorinTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
            )
    }
}
