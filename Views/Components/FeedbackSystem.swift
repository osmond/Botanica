import SwiftUI

/// Lightweight feedback overlay and toast utilities.
/// Simplified to avoid duplicate types and earlier corrupted content.
struct FeedbackOverlay: View {
    enum FeedbackType { case success, error, warning, info }
    let type: FeedbackType
    let message: String
    @Binding var isPresented: Bool
    
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0
    
    private var color: Color {
        switch type {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return BotanicaTheme.Colors.primary
        }
    }
    
    private var icon: String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var body: some View {
        if isPresented {
            HStack(spacing: BotanicaTheme.Spacing.md) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Text(message)
                    .font(BotanicaTheme.Typography.headline)
                    .foregroundColor(.primary)
            }
            .padding(BotanicaTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                    .fill(.regularMaterial)
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    scale = 1.0
                    opacity = 1.0
                }
                HapticManager.shared.light()
                Task { try? await Task.sleep(for: .seconds(2.0)); await MainActor.run { isPresented = false } }
            }
        }
    }
}

struct ToastView: View {
    let message: String
    @Binding var isPresented: Bool
    
    @State private var offsetY: CGFloat = -40
    @State private var opacity: Double = 0
    
    var body: some View {
        if isPresented {
            Text(message)
                .font(BotanicaTheme.Typography.callout)
                .padding(.horizontal, BotanicaTheme.Spacing.lg)
                .padding(.vertical, BotanicaTheme.Spacing.sm)
                .background(Capsule().fill(.regularMaterial))
                .offset(y: offsetY)
                .opacity(opacity)
                .onAppear {
                    HapticManager.shared.light()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                        offsetY = 0
                        opacity = 1
                    }
                    Task { try? await Task.sleep(for: .seconds(2.0)); await MainActor.run { isPresented = false } }
                }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FeedbackOverlay(type: .success, message: "Saved", isPresented: .constant(true))
        ToastView(message: "Welcome", isPresented: .constant(true))
    }
    .padding()
}

