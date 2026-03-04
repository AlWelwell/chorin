import SwiftUI

struct LoginView: View {
    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()
            Text("Login")
                .foregroundStyle(ChorinTheme.textPrimary)
        }
    }
}
