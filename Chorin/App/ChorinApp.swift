import SwiftUI

@main
struct ChorinApp: App {
    @State private var appState = AppState()

    init() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(red: 0.086, green: 0.067, blue: 0.063, alpha: 1)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(red: 0.086, green: 0.067, blue: 0.063, alpha: 1)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(red: 0.96, green: 0.92, blue: 0.89, alpha: 1)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(red: 0.96, green: 0.92, blue: 0.89, alpha: 1)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        UITableView.appearance().backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .task { await appState.bootstrap() }
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isLoading {
                ZStack {
                    ChorinTheme.background.ignoresSafeArea()
                    ProgressView()
                        .tint(ChorinTheme.primary)
                }
            } else if !appState.isAuthenticated {
                LoginView()
            } else if !appState.hasHousehold {
                OnboardingView()
            } else {
                ContentView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: appState.hasHousehold)
    }
}
