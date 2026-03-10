import Foundation
import Supabase

// MARK: - SupabaseManager

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let supabaseURL = Self.requireSetting(named: "SUPABASE_URL")
        let supabaseAnonKey = Self.requireSetting(named: "SUPABASE_ANON_KEY")

        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid SUPABASE_URL in Chorin config: \(supabaseURL)")
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey
        )
    }

    private static func requireSetting(named key: String) -> String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            !value.isEmpty,
            !value.contains("your-project"),
            value != "your-anon-key"
        else {
            fatalError("Missing \(key). Configure Chorin/Config.local.xcconfig before running the app.")
        }

        return value
    }
}
