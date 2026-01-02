import SwiftUI

struct CoachCard: View {
    let suggestion: CoachSuggestion
    let onAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(BotanicaTheme.Colors.primary)
                Text(suggestion.title)
                    .font(BotanicaTheme.Typography.headline)
                Spacer()
                Text("Why?")
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    .help(suggestion.reason)
            }
            Text(suggestion.message)
                .font(BotanicaTheme.Typography.callout)
                .foregroundColor(BotanicaTheme.Colors.textSecondary)
            if let onAction {
                Button("Do it", action: onAction)
                    .buttonStyle(.borderedProminent)
                    .tint(BotanicaTheme.Colors.primary)
            }
        }
        .padding(BotanicaTheme.Spacing.md)
        .cardStyle()
        .accessibilityLabel("Coach suggestion: \(suggestion.title)")
    }
}

