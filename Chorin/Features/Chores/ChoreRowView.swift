import SwiftUI

struct ChoreRowView: View {
    let chore: ChoreWithCompletion
    let isParent: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Checkbox
            Button(action: onToggle) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(chore.isCompleted ? ChorinTheme.success : .clear)
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(
                                chore.isCompleted ? ChorinTheme.success : ChorinTheme.surfaceBorder,
                                lineWidth: 1.5
                            )
                    )
                    .overlay(
                        Group {
                            if chore.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    )
            }
            .buttonStyle(.plain)

            // MARK: - Emoji icon
            Text(chore.icon)
                .font(.system(size: 18))
                .frame(width: 36, height: 36)
                .background(ChorinTheme.tertiary)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // MARK: - Chore name
            Text(chore.name)
                .font(.system(size: 14))
                .foregroundStyle(chore.isCompleted ? ChorinTheme.textMuted : ChorinTheme.textPrimary)
                .strikethrough(chore.isCompleted, color: ChorinTheme.textMuted)

            Spacer()

            // MARK: - Dollar value
            Text(chore.value.formatted(.currency(code: "USD")))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ChorinTheme.primary)
        }
        .padding(14)
        .background(ChorinTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: chore.isCompleted)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if isParent {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.orange)
            }
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        ChoreRowView(
            chore: ChoreWithCompletion(
                id: UUID(), name: "Make bed", value: 1.00,
                icon: "🛏️", completionId: nil, isCompleted: false
            ),
            isParent: true,
            onToggle: {}, onEdit: {}, onDelete: {}
        )
        ChoreRowView(
            chore: ChoreWithCompletion(
                id: UUID(), name: "Load dishwasher", value: 2.50,
                icon: "🍽️", completionId: UUID(), isCompleted: true
            ),
            isParent: false,
            onToggle: {}, onEdit: {}, onDelete: {}
        )
    }
    .padding()
    .background(ChorinTheme.background)
}
