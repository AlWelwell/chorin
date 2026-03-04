import SwiftUI

struct HouseholdView: View {
    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()
            Text("Household")
                .foregroundStyle(ChorinTheme.textPrimary)
        }
    }
}
