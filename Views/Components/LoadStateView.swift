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
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text("Something went wrong")
                    .font(BotanicaTheme.Typography.headline)
                Text(message)
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                if let retry {
                    Button("Retry") { retry() }
                        .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}
