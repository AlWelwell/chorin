import SwiftUI

struct OnboardingView: View {
    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()
            Text("Onboarding")
                .foregroundStyle(ChorinTheme.textPrimary)
        }
    }
}
