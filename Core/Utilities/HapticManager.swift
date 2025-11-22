import UIKit

/// Manages haptic feedback throughout the Botanica app
/// Provides contextual haptic feedback for different user interactions
@MainActor
final class HapticManager: Sendable {
    
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Feedback Types
    
    /// Light haptic feedback for subtle interactions
    func light() {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        impactFeedbackGenerator.prepare()
        impactFeedbackGenerator.impactOccurred()
    }
    
    /// Medium haptic feedback for standard interactions
    func medium() {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactFeedbackGenerator.prepare()
        impactFeedbackGenerator.impactOccurred()
    }
    
    /// Heavy haptic feedback for significant interactions
    func heavy() {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedbackGenerator.prepare()
        impactFeedbackGenerator.impactOccurred()
    }
    
    /// Success haptic feedback for positive actions
    func success() {
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
    
    /// Warning haptic feedback for cautionary actions
    func warning() {
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.warning)
    }
    
    /// Error haptic feedback for failed actions
    func error() {
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.error)
    }
    
    // MARK: - Contextual Feedback
    
    /// Haptic feedback for care actions (watering, fertilizing)
    func careAction() {
        success()
    }
    
    /// Haptic feedback for adding new plants
    func plantAdded() {
        success()
    }
    
    /// Haptic feedback for reminder actions
    func reminderSet() {
        light()
    }
    
    /// Haptic feedback for navigation actions
    func navigation() {
        light()
    }
    
    /// Haptic feedback for selection actions
    func selection() {
        light()
    }
}