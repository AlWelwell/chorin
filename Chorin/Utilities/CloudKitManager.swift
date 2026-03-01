import Foundation
import Supabase

// MARK: - SupabaseManager

final class SupabaseManager {
    static let shared = SupabaseManager()

    // TODO: Replace with your Supabase project URL
    private let supabaseURL = "https://YOUR_PROJECT.supabase.co"
    // TODO: Replace with your Supabase anon key
    private let supabaseAnonKey = "YOUR_ANON_KEY"

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseAnonKey
        )
    }
}
