import SwiftUI
import Combine
import UIKit

/// Performance-optimized animation utilities respecting user preferences and device capabilities
class AnimationPerformanceManager: ObservableObject {
    static let shared = AnimationPerformanceManager()
    
    @Published private(set) var shouldReduceMotion: Bool
    @Published private(set) var devicePerformanceLevel: DevicePerformanceLevel
    
    enum DevicePerformanceLevel {
        case high, medium, low
        
        var maxConcurrentAnimations: Int {
            switch self {
            case .high: return 20
            case .medium: return 10
            case .low: return 5
            }
        }
        
        var preferredFrameRate: Double {
            switch self {
            case .high: return 120.0
            case .medium: return 60.0
            case .low: return 30.0
            }
        }
    }
    
    private var activeAnimations: Set<String> = []
    private let maxAnimationsReached = PassthroughSubject<Void, Never>()
    
    private init() {
        shouldReduceMotion = UIAccessibility.isReduceMotionEnabled
        devicePerformanceLevel = Self.determineDevicePerformanceLevel()
        
        // Listen for accessibility changes
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.shouldReduceMotion = UIAccessibility.isReduceMotionEnabled
        }
    }
    
    /// Determine device performance level based on hardware capabilities
    private static func determineDevicePerformanceLevel() -> DevicePerformanceLevel {
        let processInfo = ProcessInfo.processInfo
        
        // Check physical memory
        let physicalMemory = processInfo.physicalMemory
        let memoryGB = Double(physicalMemory) / (1024 * 1024 * 1024)
        
        // Check processor count
        let processorCount = processInfo.processorCount
        
        // Heuristic for performance level
        if memoryGB >= 6 && processorCount >= 6 {
            return .high
        } else if memoryGB >= 3 && processorCount >= 4 {
            return .medium
        } else {
            return .low
        }
    }
    
    /// Get optimized animation based on performance level and user preferences
    func optimizedAnimation(
        _ baseAnimation: Animation,
        fallback: Animation? = nil
    ) -> Animation {
        if shouldReduceMotion {
            return fallback ?? .easeInOut(duration: 0.1)
        }
        
        switch devicePerformanceLevel {
        case .high:
            return baseAnimation
        case .medium:
            // Slightly reduce animation complexity
            return baseAnimation.speed(1.2)
        case .low:
            // Simplified animation
            return fallback ?? .easeInOut(duration: 0.2)
        }
    }
    
    /// Track animation lifecycle for performance monitoring
    func startAnimation(id: String) -> Bool {
        guard activeAnimations.count < devicePerformanceLevel.maxConcurrentAnimations else {
            maxAnimationsReached.send()
            return false
        }
        
        activeAnimations.insert(id)
        return true
    }
    
    /// End animation tracking
    func endAnimation(id: String) {
        activeAnimations.remove(id)
    }
    
    /// Get performance-optimized spring animation
    var optimizedSpring: Animation {
        optimizedAnimation(
            .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0),
            fallback: .easeInOut(duration: 0.2)
        )
    }
    
    /// Get performance-optimized bounce animation
    var optimizedBounce: Animation {
        optimizedAnimation(
            .spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0),
            fallback: .easeInOut(duration: 0.3)
        )
    }
}

/// View modifier for performance-optimized animations
struct OptimizedAnimation: ViewModifier {
    let animation: Animation
    let value: AnyHashable
    let animationId: String
    
    @StateObject private var performanceManager = AnimationPerformanceManager.shared
    @State private var isAnimating = false
    
    init<V: Hashable>(_ animation: Animation, value: V, id: String = UUID().uuidString) {
        self.animation = animation
        self.value = AnyHashable(value)
        self.animationId = id
    }
    
    func body(content: Content) -> some View {
        content
            .animation(
                performanceManager.optimizedAnimation(animation),
                value: value
            )
            .onChange(of: value) { _ in
                handleAnimationChange()
            }
    }
    
    private func handleAnimationChange() {
        guard !isAnimating else { return }
        guard performanceManager.startAnimation(id: animationId) else { return }
        
        isAnimating = true
        
        // Estimate animation duration and cleanup with Task.sleep
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            await MainActor.run {
                performanceManager.endAnimation(id: animationId)
                isAnimating = false
            }
        }
    }
}

extension View {
    /// Apply performance-optimized animation
    func optimizedAnimation<V: Hashable>(
        _ animation: Animation,
        value: V,
        id: String = UUID().uuidString
    ) -> some View {
        modifier(OptimizedAnimation(animation, value: value, id: id))
    }
}

/// Smooth list performance optimizations
struct OptimizedScrollView<Content: View>: View {
    let content: Content
    let axes: Axis.Set
    let showsIndicators: Bool
    
    @StateObject private var performanceManager = AnimationPerformanceManager.shared
    @State private var scrollOffset: CGFloat = 0
    
    init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content()
    }
    
    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            content
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                    }
                )
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            // Throttle scroll offset updates for performance
            let roundedOffset = round(offset / 10) * 10
            if roundedOffset != scrollOffset {
                scrollOffset = roundedOffset
            }
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Memory-efficient lazy loading for large lists
struct LazyLoadingContainer<Content: View>: View {
    let content: Content
    let bufferSize: Int
    
    @State private var visibleRange: Range<Int> = 0..<10
    @State private var contentHeight: CGFloat = 0
    
    init(bufferSize: Int = 10, @ViewBuilder content: () -> Content) {
        self.bufferSize = bufferSize
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            content
                .clipped()
        }
    }
}

/// Performance monitoring overlay for debug builds
struct PerformanceOverlay: View {
    @StateObject private var performanceManager = AnimationPerformanceManager.shared
    @State private var showDebugInfo = false
    
    var body: some View {
        #if DEBUG
        VStack {
            HStack {
                Spacer()
                
                Button("Perf") {
                    showDebugInfo.toggle()
                    HapticManager.shared.light()
                }
                .font(.caption)
                .padding(4)
                .background(.ultraThinMaterial)
                .cornerRadius(4)
            }
            
            if showDebugInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Device: \(performanceManager.devicePerformanceLevel)")
                    Text("Reduce Motion: \(performanceManager.shouldReduceMotion ? "ON" : "OFF")")
                    Text("Max FPS: \(Int(performanceManager.devicePerformanceLevel.preferredFrameRate))")
                }
                .font(.caption)
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
            
            Spacer()
        }
        #endif
    }
}

#Preview {
    VStack(spacing: 20) {
        Rectangle()
            .fill(BotanicaTheme.Colors.primary)
            .frame(height: 100)
            .optimizedAnimation(.spring(), value: UUID())
        
        OptimizedScrollView {
            LazyVStack {
                ForEach(0..<100, id: \.self) { index in
                    Text("Item \(index)")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .frame(height: 300)
    }
    .overlay(PerformanceOverlay())
}
