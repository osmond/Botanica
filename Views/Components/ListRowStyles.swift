import SwiftUI

// Shared list row styling helpers to reduce repeated modifiers
extension View {
    /// Hides separator and removes default insets for a cleaner card list look
    func listClearRow() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
    }

    /// Standard card row: clear row chrome plus vertical padding
    func cardListRow(padding: CGFloat = BotanicaTheme.Spacing.xs) -> some View {
        self
            .listClearRow()
            .padding(.vertical, padding)
    }
}

