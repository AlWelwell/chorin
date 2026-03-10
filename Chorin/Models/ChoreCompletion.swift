import Foundation

/// Formatter for PostgreSQL `date` columns which return "yyyy-MM-dd" (no time component).
/// The Supabase SDK's default decoder only handles ISO 8601 datetime formats with a time
/// component, so we decode this field manually.
private let postgresDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

struct ChoreCompletion: Codable, Identifiable {
    let id: UUID
    let choreId: UUID
    let userId: UUID
    let date: Date
    let earnedAmount: Decimal
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case choreId = "chore_id"
        case userId = "user_id"
        case date
        case earnedAmount = "earned_amount"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        choreId = try container.decode(UUID.self, forKey: .choreId)
        userId = try container.decode(UUID.self, forKey: .userId)
        earnedAmount = try container.decode(Decimal.self, forKey: .earnedAmount)
        createdAt = try container.decode(Date.self, forKey: .createdAt)

        let dateString = try container.decode(String.self, forKey: .date)
        guard let parsed = postgresDateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .date, in: container,
                debugDescription: "Expected yyyy-MM-dd date, got: \(dateString)"
            )
        }
        date = parsed
    }
}

// Used in EarningsView — completion joined with its chore info
struct ChoreCompletionWithChore: Codable, Identifiable {
    let id: UUID
    let choreId: UUID
    let userId: UUID
    let date: Date
    let earnedAmount: Decimal
    let createdAt: Date
    let chore: ChoreInfo

    enum CodingKeys: String, CodingKey {
        case id
        case choreId = "chore_id"
        case userId = "user_id"
        case date
        case earnedAmount = "earned_amount"
        case createdAt = "created_at"
        case chore = "chores"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        choreId = try container.decode(UUID.self, forKey: .choreId)
        userId = try container.decode(UUID.self, forKey: .userId)
        earnedAmount = try container.decode(Decimal.self, forKey: .earnedAmount)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        chore = try container.decode(ChoreInfo.self, forKey: .chore)

        let dateString = try container.decode(String.self, forKey: .date)
        guard let parsed = postgresDateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .date, in: container,
                debugDescription: "Expected yyyy-MM-dd date, got: \(dateString)"
            )
        }
        date = parsed
    }
}

struct ChoreInfo: Codable {
    let name: String
    let icon: String
}
