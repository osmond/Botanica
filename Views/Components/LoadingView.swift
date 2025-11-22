import SwiftUI

/// Beautiful loading view with plant-themed animations
struct LoadingView: View {
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            // Animated plant icon
            ZStack {
                // Outer ring
                Circle()
                    .stroke(BotanicaTheme.Colors.primary.opacity(0.2), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                // Animated progress ring
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        BotanicaTheme.Gradients.primary,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: rotationAngle)
                
                // Central plant icon
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(BotanicaTheme.Colors.primary)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            // Loading text
            Text(message)
                .font(BotanicaTheme.Typography.headline)
                .foregroundColor(BotanicaTheme.Colors.textPrimary)
                .opacity(isAnimating ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            
            // Animated dots
            HStack(spacing: BotanicaTheme.Spacing.sm) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(BotanicaTheme.Colors.primary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
        }
        .onAppear {
            isAnimating = true
            rotationAngle = 360
        }
    }
}

/// Compact loading indicator for inline use
struct CompactLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.sm) {
            Image(systemName: "leaf.fill")
                .font(.callout)
                .foregroundColor(BotanicaTheme.Colors.primary)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
            
            Text("Loading...")
                .font(BotanicaTheme.Typography.callout)
                .foregroundColor(.secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

/// Skeleton loader for content placeholders
struct SkeletonView: View {
    @State private var isAnimating = false
    
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 20, cornerRadius: CGFloat = BotanicaTheme.CornerRadius.small) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(x: isAnimating ? 1 : 0.8, anchor: .leading)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    VStack(spacing: 40) {
        LoadingView(message: "Growing your garden...")
        
        CompactLoadingView()
        
        VStack(spacing: 12) {
            SkeletonView(height: 60, cornerRadius: 8)
            SkeletonView(height: 20)
            SkeletonView(height: 16)
        }
        .padding()
    }
    .padding()
}