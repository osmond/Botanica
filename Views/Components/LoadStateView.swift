import SwiftUI

/// Lightweight wrapper to show loading / error states while keeping main content tidy.
struct LoadStateView<Content: View, Loading: View>: View {
    let state: LoadState
    let retry: (() -> Void)?
    let loading: () -> Loading
    let content: () -> Content
    
    init(
        state: LoadState,
        retry: (() -> Void)? = nil,
        @ViewBuilder loading: @escaping () -> Loading,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.state = state
        self.retry = retry
        self.loading = loading
        self.content = content
    }
    
    var body: some View {
        switch state {
        case .loading:
            loading()
        case .idle, .loaded:
            content()
        case .failed(let message):
            VStack(spacing: BotanicaTheme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(BotanicaTheme.Typography.largeTitle)
                    .foregroundColor(BotanicaTheme.Colors.warning)
                Text("Something went wrong")
                    .font(BotanicaTheme.Typography.headline)
                Text(message)
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                if let retry {
                    Button("Retry") { retry() }
                        .primaryButtonStyle()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}
