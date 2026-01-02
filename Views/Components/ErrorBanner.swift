import SwiftUI

/// Minimal error banner used across the app.
struct ErrorBanner: View {
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            HStack(spacing: BotanicaTheme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(BotanicaTheme.Colors.warning)
                Text(title)
                    .font(BotanicaTheme.Typography.headline)
            }
            Text(message)
                .font(BotanicaTheme.Typography.callout)
                .foregroundColor(BotanicaTheme.Colors.textSecondary)
            if let actionLabel, let action {
                Button(actionLabel) { action() }
                    .primaryButtonStyle()
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(BotanicaTheme.Colors.warning.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .stroke(BotanicaTheme.Colors.warning.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    ErrorBanner(
        title: "Identification Failed",
        message: "Please check your network and try again.",
        actionLabel: "Retry",
        action: {}
    )
}
