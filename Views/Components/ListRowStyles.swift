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
    
    /// Consistent card styling for dashboard elements
    func cardStyle(
        cornerRadius: CGFloat = BotanicaTheme.CornerRadius.large,
        background: Color = Color(.secondarySystemGroupedBackground),
        strokeColor: Color = BotanicaTheme.Colors.primary.opacity(0.06),
        shadow: Color = Color.black.opacity(0.04),
        shadowRadius: CGFloat = 8,
        shadowY: CGFloat = 2
    ) -> some View {
        self
            .padding(BotanicaTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(background)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(strokeColor, lineWidth: 1)
                    )
            )
            .shadow(color: shadow, radius: shadowRadius, x: 0, y: shadowY)
    }
}
