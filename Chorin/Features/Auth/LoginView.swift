import SwiftUI
import Supabase

struct LoginView: View {
    @Environment(AppState.self) private var appState

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // MARK: - Logo & Subtitle

                VStack(spacing: 8) {
                    Text("Chorin'")
                        .font(.system(size: 40, weight: .bold, design: .serif))
                        .foregroundStyle(ChorinTheme.primary)

                    Text("Track chores. Earn allowance.")
                        .font(.title3)
                        .foregroundStyle(ChorinTheme.textSecondary)
                }

                // MARK: - Input Fields

                VStack(spacing: 14) {
                    ChorinTextField(
                        placeholder: "Email",
                        text: $email
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)

                    ChorinTextField(
                        placeholder: "Password",
                        text: $password,
                        isSecure: true
                    )
                    .textContentType(isSignUp ? .newPassword : .password)
                }
                .padding(.horizontal, 32)

                // MARK: - Error Message

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(ChorinTheme.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // MARK: - Submit Button

                ChorinButton(
                    title: isSignUp ? "Create Account" : "Sign In",
                    style: .primary,
                    isLoading: isLoading
                ) {
                    Task { await submit() }
                }
                .disabled(email.isEmpty || password.isEmpty)
                .padding(.horizontal, 32)

                // MARK: - Toggle Sign In / Sign Up

                Button {
                    withAnimation { isSignUp.toggle() }
                    errorMessage = nil
                } label: {
                    if isSignUp {
                        Text("Already have an account? ")
                            .foregroundStyle(ChorinTheme.textMuted)
                        + Text("Sign In")
                            .foregroundStyle(ChorinTheme.primary)
                    } else {
                        Text("Don't have an account? ")
                            .foregroundStyle(ChorinTheme.textMuted)
                        + Text("Sign Up")
                            .foregroundStyle(ChorinTheme.primary)
                    }
                }
                .font(.subheadline)

                Spacer()
            }
        }
    }

    // MARK: - Submit

    private func submit() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if isSignUp {
                try await supabase.auth.signUp(email: email, password: password)
            } else {
                try await supabase.auth.signIn(email: email, password: password)
            }
            await appState.bootstrap()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
        .environment(AppState())
}
