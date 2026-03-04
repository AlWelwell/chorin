import SwiftUI
import Supabase

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    enum Mode { case choose, create, join }
    @State private var mode: Mode = .choose

    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()

            switch mode {
            case .choose:
                ChooseView(mode: $mode)
                    .transition(.opacity)
            case .create:
                CreateHouseholdView(mode: $mode)
                    .transition(.move(edge: .trailing))
            case .join:
                JoinHouseholdView(mode: $mode)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: mode)
    }
}

// MARK: - Choose

private struct ChooseView: View {
    @Binding var mode: OnboardingView.Mode

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // MARK: - Heading

            VStack(spacing: 8) {
                Text("Welcome to Chorin'")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(ChorinTheme.primary)

                Text("Set up your household to get started.")
                    .font(.subheadline)
                    .foregroundStyle(ChorinTheme.textSecondary)
            }

            Spacer()

            // MARK: - Option Cards

            VStack(spacing: 16) {
                ChorinCard {
                    Button {
                        mode = .create
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "house.fill")
                                .font(.title2)
                                .foregroundStyle(ChorinTheme.primary)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("I'm a Parent")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(ChorinTheme.textPrimary)

                                Text("Create a new household")
                                    .font(.subheadline)
                                    .foregroundStyle(ChorinTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ChorinTheme.textMuted)
                        }
                    }
                }

                ChorinCard {
                    Button {
                        mode = .join
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "person.badge.plus")
                                .font(.title2)
                                .foregroundStyle(ChorinTheme.success)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("I'm a Child")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(ChorinTheme.textPrimary)

                                Text("Join with an invite code")
                                    .font(.subheadline)
                                    .foregroundStyle(ChorinTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ChorinTheme.textMuted)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

// MARK: - Create Household

private struct CreateHouseholdView: View {
    @Binding var mode: OnboardingView.Mode
    @Environment(AppState.self) private var appState

    @State private var householdName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    private var canSubmit: Bool {
        !householdName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Top Bar

            HStack {
                Button {
                    mode = .choose
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(ChorinTheme.primary)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            Spacer()

            // MARK: - Content

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Create Household")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(ChorinTheme.primary)

                    Text("You'll be added as a parent. Share the invite code later so your children can join.")
                        .font(.subheadline)
                        .foregroundStyle(ChorinTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                VStack(spacing: 14) {
                    ChorinTextField(
                        placeholder: "Household name (e.g. The Smiths)",
                        text: $householdName
                    )
                    .textInputAutocapitalization(.words)
                }
                .padding(.horizontal, 32)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(ChorinTheme.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                ChorinButton(
                    title: "Create Household",
                    style: .primary,
                    isLoading: isLoading
                ) {
                    Task { await create() }
                }
                .disabled(!canSubmit)
                .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Create

    private func create() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.rpc(
                "create_household_with_parent",
                params: ["p_household_name": householdName.trimmingCharacters(in: .whitespaces)]
            ).execute()
            await appState.loadHouseholdAndMember()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Join Household

private struct JoinHouseholdView: View {
    @Binding var mode: OnboardingView.Mode
    @Environment(AppState.self) private var appState

    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    private var canSubmit: Bool { inviteCode.count == 6 }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Top Bar

            HStack {
                Button {
                    mode = .choose
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(ChorinTheme.primary)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            Spacer()

            // MARK: - Content

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Join Household")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(ChorinTheme.primary)

                    Text("Ask a parent in your household for the 6-character invite code.")
                        .font(.subheadline)
                        .foregroundStyle(ChorinTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                VStack(spacing: 14) {
                    ChorinTextField(
                        placeholder: "6-character invite code",
                        text: $inviteCode
                    )
                    .textInputAutocapitalization(.characters)
                    .onChange(of: inviteCode) { _, newValue in
                        inviteCode = String(newValue.prefix(6)).uppercased()
                    }
                }
                .padding(.horizontal, 32)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(ChorinTheme.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                ChorinButton(
                    title: "Join Household",
                    style: .primary,
                    isLoading: isLoading
                ) {
                    Task { await join() }
                }
                .disabled(!canSubmit)
                .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Join

    private func join() async {
        guard let userId = appState.session?.user.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Look up household by invite code
            let results: [Household] = try await supabase
                .rpc("lookup_household_by_invite_code", params: ["p_invite_code": inviteCode])
                .execute()
                .value

            guard let found = results.first else {
                errorMessage = "No household found with that code. Check the code and try again."
                return
            }

            // Insert membership as child
            try await supabase
                .from("household_members")
                .insert([
                    "household_id": found.id.uuidString,
                    "user_id": userId.uuidString,
                    "role": "child"
                ])
                .execute()

            await appState.loadHouseholdAndMember()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environment(AppState())
}
