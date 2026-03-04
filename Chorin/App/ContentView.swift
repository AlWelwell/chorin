import SwiftUI

struct ContentView: View {
    @State private var selectedTab: ChorinTab = .chores

    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .chores:
                        NavigationStack { ChoreListView() }
                    case .earnings:
                        NavigationStack { EarningsView() }
                    case .savings:
                        NavigationStack { SavingsView() }
                    case .household:
                        NavigationStack { HouseholdView() }
                    }
                }
                .frame(maxHeight: .infinity)

                ChorinTabBar(selected: $selectedTab)
                    .padding(.bottom, 8)
            }
        }
    }
}
