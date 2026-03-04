import SwiftUI

enum ChorinTab: String, CaseIterable {
    case chores, earnings, savings, household

    var label: String {
        switch self {
        case .chores: "Chores"
        case .earnings: "Earnings"
        case .savings: "Savings"
        case .household: "Home"
        }
    }

    var icon: String {
        switch self {
        case .chores: "checkmark.square"
        case .earnings: "dollarsign"
        case .savings: "arrow.down.circle"
        case .household: "house"
        }
    }
}

struct ChorinTabBar: View {
    @Binding var selected: ChorinTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ChorinTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))

                        if selected == tab {
                            Text(tab.label)
                                .font(.system(size: 11, weight: .semibold))
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .foregroundStyle(selected == tab ? ChorinTheme.primary : ChorinTheme.textMuted)
                    .padding(.horizontal, selected == tab ? 14 : 12)
                    .padding(.vertical, 10)
                    .background(
                        selected == tab ? ChorinTheme.tertiary : .clear,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
            }
        }
        .padding(6)
        .background(ChorinTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
        )
    }
}
