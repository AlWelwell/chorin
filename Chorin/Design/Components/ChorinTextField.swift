import SwiftUI

struct ChorinTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(14)
        .background(ChorinTheme.background)
        .foregroundStyle(ChorinTheme.textPrimary)
        .clipShape(RoundedRectangle(cornerRadius: ChorinTheme.radiusSM))
        .overlay(
            RoundedRectangle(cornerRadius: ChorinTheme.radiusSM)
                .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1.5)
        )
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
    }
}
