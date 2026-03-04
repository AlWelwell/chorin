import SwiftUI

struct EarningsView: View {
    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()
            Text("Earnings")
                .foregroundStyle(ChorinTheme.textPrimary)
        }
    }
}
