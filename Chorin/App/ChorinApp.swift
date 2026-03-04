import SwiftUI

@main
struct ChorinApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Chorin'")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundStyle(Color(red: 1.0, green: 0.565, blue: 0.502))
        }
        .preferredColorScheme(.dark)
    }
}
