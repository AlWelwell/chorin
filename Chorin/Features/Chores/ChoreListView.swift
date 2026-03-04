import SwiftUI

struct ChoreListView: View {
    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()
            Text("Chores")
                .foregroundStyle(ChorinTheme.textPrimary)
        }
    }
}
