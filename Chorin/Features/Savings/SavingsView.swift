import SwiftUI

struct SavingsView: View {
    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()
            Text("Savings")
                .foregroundStyle(ChorinTheme.textPrimary)
        }
    }
}
