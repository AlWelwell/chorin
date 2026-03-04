import SwiftUI

struct WeekHistoryView: View {
    let weekStart: Date
    let completions: [ChoreCompletionWithChore]

    // MARK: - Derived data

    private var weekRange: ClosedRange<Date> { WeekHelper.weekRange(for: weekStart) }

    private var weekTotal: Decimal {
        WeekHelper.totalEarnings(from: completions, in: weekRange)
    }

    private var dailyBreakdown: [(date: Date, total: Decimal)] {
        WeekHelper.earningsByDay(from: completions, in: weekRange)
    }

    private var choreBreakdown: [(name: String, total: Decimal, count: Int)] {
        WeekHelper.earningsByChore(from: completions, in: weekRange)
    }

    private var maxDayEarning: Decimal {
        weekDays.map(\.total).max() ?? 1
    }

    // MARK: - All 7 days of the week

    private var weekDays: [(date: Date, total: Decimal)] {
        let calendar = Calendar.current
        let start = WeekHelper.startOfCurrentWeek(from: weekStart)
        var days: [(date: Date, total: Decimal)] = []

        // Build a lookup from the earningsByDay data
        var lookup: [Date: Decimal] = [:]
        for item in dailyBreakdown {
            let dayStart = calendar.startOfDay(for: item.date)
            lookup[dayStart] = item.total
        }

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: start)!
            let dayStart = calendar.startOfDay(for: date)
            days.append((date: dayStart, total: lookup[dayStart] ?? 0))
        }
        return days
    }

    // MARK: - Dark text for coral gradient

    private let heroText = Color(hex: "161110")

    // MARK: - Body

    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()

            if dailyBreakdown.isEmpty && choreBreakdown.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        heroCard
                        dailyBreakdownSection
                        perChoreSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle(WeekHelper.weekLabel(for: weekStart))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(spacing: 12) {
            Text("Week total")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(heroText.opacity(0.7))

            Text(weekTotal.formatted(.currency(code: "USD")))
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(heroText)

            Text(WeekHelper.weekLabel(for: weekStart))
                .font(.system(size: 12))
                .foregroundStyle(heroText.opacity(0.5))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(ChorinTheme.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Daily Breakdown

    private var dailyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DAILY BREAKDOWN")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ChorinTheme.textMuted)
                .tracking(0.8)

            ForEach(weekDays, id: \.date) { day in
                dailyRow(day: day)
            }
        }
    }

    private func dailyRow(day: (date: Date, total: Decimal)) -> some View {
        HStack(spacing: 12) {
            Text(day.date, format: .dateTime.weekday(.abbreviated))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ChorinTheme.textSecondary)
                .frame(width: 36, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ChorinTheme.surfaceBorder)
                        .frame(height: 8)

                    if day.total > 0, maxDayEarning > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ChorinTheme.primary)
                            .frame(
                                width: max(8, geo.size.width * CGFloat(truncating: (day.total / maxDayEarning) as NSDecimalNumber)),
                                height: 8
                            )
                    }
                }
            }
            .frame(height: 8)

            Text(day.total.formatted(.currency(code: "USD")))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(day.total > 0 ? ChorinTheme.textPrimary : ChorinTheme.textMuted)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ChorinTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
        )
    }

    // MARK: - Per Chore

    private var perChoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !choreBreakdown.isEmpty {
                Text("PER CHORE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ChorinTheme.textMuted)
                    .tracking(0.8)

                ForEach(choreBreakdown, id: \.name) { item in
                    choreRow(item: item)
                }
            }
        }
    }

    private func choreRow(item: (name: String, total: Decimal, count: Int)) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ChorinTheme.textPrimary)
                Text("\(item.count) time\(item.count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(ChorinTheme.textMuted)
            }

            Spacer()

            Text(item.total.formatted(.currency(code: "USD")))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ChorinTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ChorinTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 48))
                .foregroundStyle(ChorinTheme.textMuted)

            Text("No Earnings")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(ChorinTheme.textPrimary)

            Text("No chores were completed this week")
                .font(.system(size: 14))
                .foregroundStyle(ChorinTheme.textMuted)
        }
    }
}

#Preview {
    NavigationStack {
        WeekHistoryView(
            weekStart: WeekHelper.startOfCurrentWeek(),
            completions: []
        )
    }
}
