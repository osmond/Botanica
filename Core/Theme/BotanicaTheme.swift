import SwiftUI

/// Botanica's design system providing colors, typography, and spacing constants
/// following iOS design guidelines and botanical aesthetics
struct BotanicaTheme {
    
    // MARK: - Colors
    
    /// Semantic color palette following iOS 26 design principles with botanical inspiration
    struct Colors {
        // Primary brand colors - refined for better contrast and vibrancy
        static let leafGreen = Color(red: 0.18, green: 0.73, blue: 0.33)      // Improved contrast
        static let forestGreen = Color(red: 0.11, green: 0.58, blue: 0.15)    // Deeper, richer
        static let mintGreen = Color(red: 0.55, green: 0.94, blue: 0.62)      // Softer mint
        
        // Earth tones refined for modern UI
        static let soilBrown = Color(red: 0.48, green: 0.35, blue: 0.22)      // Warmer, more sophisticated
        static let terracotta = Color(red: 0.82, green: 0.49, blue: 0.25)     // More vibrant
        static let creamWhite = Color(red: 0.98, green: 0.97, blue: 0.94)     // Subtle warmth
        
        // Care-specific colors with enhanced accessibility
        static let waterBlue = Color(red: 0.20, green: 0.67, blue: 0.95)      // More vivid, accessible
        static let sunYellow = Color(red: 0.98, green: 0.79, blue: 0.22)      // Warmer tone
        static let nutrientOrange = Color(red: 0.96, green: 0.57, blue: 0.18) // Better contrast
        
        // System integration colors
        static let primary = leafGreen
        static let secondary = forestGreen
        static let accent = terracotta
        static let background = Color(.systemBackground)
        static let surface = Color(.secondarySystemBackground)
        static let cardBackground = Color(.tertiarySystemBackground)
        
        // Status colors optimized for clarity
        static let success = Color(red: 0.20, green: 0.78, blue: 0.35)        // Custom success green
        static let warning = Color(red: 0.95, green: 0.69, blue: 0.18)        // Refined warning
        static let error = Color(red: 0.91, green: 0.30, blue: 0.24)          // iOS-style error
        static let info = waterBlue
        
        // Text colors for optimal legibility
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        
        // Interactive states
        static let tappable = primary
        static let pressed = primary.opacity(0.8)
        static let disabled = Color(.quaternaryLabel)
    }
    
    // MARK: - Typography
    
    /// iOS 26-compliant typography system with Dynamic Type support and proper hierarchy
    struct Typography {
        // MARK: - Display Hierarchy
        /// Large title for hero sections and main headers
        static let largeTitle = Font.largeTitle.weight(.heavy)
        
        /// Title 1 for primary section headers
        static let title1 = Font.title.weight(.bold)
        
        /// Title 2 for secondary section headers
        static let title2 = Font.title2.weight(.semibold)
        
        /// Title 3 for tertiary headers
        static let title3 = Font.title3.weight(.semibold)
        
        // MARK: - Body Hierarchy
        /// Headline for important content
        static let headline = Font.headline.weight(.semibold)
        
        /// Subheadline for secondary content
        static let subheadline = Font.subheadline.weight(.medium)
        
        /// Body text for primary content
        static let body = Font.body
        
        /// Body emphasized for important body text
        static let bodyEmphasized = Font.body.weight(.medium)
        
        /// Callout for emphasized content
        static let callout = Font.callout.weight(.medium)
        
        // MARK: - Supporting Text
        /// Footnote for supplementary information
        static let footnote = Font.footnote
        
        /// Caption 1 for metadata and labels
        static let caption = Font.caption.weight(.medium)
        
        /// Caption 2 for the smallest text
        static let caption2 = Font.caption2
        
        // MARK: - Interactive Elements
        /// Button text with proper emphasis
        static let button = Font.body.weight(.semibold)
        
        /// Navigation text
        static let navigation = Font.caption.weight(.medium)
        
        /// Tab bar text
        static let tabBar = Font.caption2.weight(.medium)
        
        // MARK: - Specialized
        /// Scientific names use elegant italic styling
        static let scientificName = Font.body.italic().weight(.light)
        
        /// Large scientific names for headers
        static let scientificNameLarge = Font.title3.italic().weight(.light)
        
        /// Numbers and statistics
        static let numeric = Font.body.weight(.medium).monospacedDigit()
    }
    
    // MARK: - Spacing
    
    /// iOS 26-compliant spacing system using 4pt base grid
    struct Spacing {
        static let xxs: CGFloat = 2       // Micro spacing
        static let xs: CGFloat = 4        // Tight spacing
        static let sm: CGFloat = 8        // Small spacing
        static let md: CGFloat = 16       // Standard spacing
        static let lg: CGFloat = 24       // Large spacing
        static let xl: CGFloat = 32       // Extra large
        static let xxl: CGFloat = 48      // Maximum spacing
        static let jumbo: CGFloat = 64    // Hero sections
    }
    
    // MARK: - Corner Radius
    
    /// Refined corner radius system following iOS design language
    struct CornerRadius {
        static let tight: CGFloat = 6     // Small UI elements
        static let small: CGFloat = 8     // Buttons, chips
        static let medium: CGFloat = 12   // Cards, containers
        static let large: CGFloat = 16    // Hero sections
        static let xlarge: CGFloat = 20   // Modal presentations
        static let round: CGFloat = 50    // Circular elements
        
        // Semantic radius
        static let card = medium
        static let button = small
        static let modal = large
    }
    
    // MARK: - Shadows
    
    /// Sophisticated shadow system for visual hierarchy
    struct Shadows {
        // Subtle elevation for cards
        static let card = Color.black.opacity(0.04)
        static let cardRadius: CGFloat = 8
        static let cardOffset = CGSize(width: 0, height: 2)
        
        // Interactive elements
        static let button = Color.black.opacity(0.08)
        static let buttonRadius: CGFloat = 4
        static let buttonOffset = CGSize(width: 0, height: 1)
        
        // Pressed state
        static let buttonPressed = Color.black.opacity(0.12)
        static let buttonPressedRadius: CGFloat = 6
        static let buttonPressedOffset = CGSize(width: 0, height: 3)
        
        // Hero sections and modals
        static let hero = Color.black.opacity(0.10)
        static let heroRadius: CGFloat = 16
        static let heroOffset = CGSize(width: 0, height: 8)
        
        // Floating action button
        static let fab = Color.black.opacity(0.15)
        static let fabRadius: CGFloat = 12
        static let fabOffset = CGSize(width: 0, height: 6)
    }
    
    // MARK: - Gradients
    
    /// Sophisticated gradient system for visual depth and engagement
    struct Gradients {
        static let primary = LinearGradient(
            colors: [Colors.leafGreen, Colors.forestGreen.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let hero = LinearGradient(
            colors: [
                Colors.leafGreen.opacity(0.95),
                Colors.forestGreen.opacity(0.85),
                Colors.mintGreen.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let card = LinearGradient(
            colors: [
                Colors.surface,
                Colors.cardBackground.opacity(0.8)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let sunset = LinearGradient(
            colors: [
                Colors.nutrientOrange,
                Colors.terracotta,
                Colors.soilBrown.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let water = LinearGradient(
            colors: [
                Colors.waterBlue.opacity(0.8),
                Colors.waterBlue.opacity(0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let success = LinearGradient(
            colors: [
                Colors.success.opacity(0.9),
                Colors.leafGreen.opacity(0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let warning = LinearGradient(
            colors: [
                Colors.warning.opacity(0.9),
                Colors.nutrientOrange.opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Animation
    
    /// iOS 26-compliant animation system with sophisticated motion design
    struct Animation {
        // MARK: - Basic Timing
        /// Quick interactions (buttons, toggles)
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        
        /// Standard transitions (view changes, modal presentation)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.25)
        
        /// Deliberate actions (sheet dismissal, complex transitions)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.35)
        
        /// Extended animations (hero transitions, onboarding)
        static let extended = SwiftUI.Animation.easeInOut(duration: 0.5)
        
        // MARK: - Spring Animations
        /// Responsive spring for interactive elements
        static let spring = SwiftUI.Animation.spring(
            response: 0.4,
            dampingFraction: 0.75,
            blendDuration: 0.2
        )
        
        /// Bouncy spring for playful interactions
        static let bounce = SwiftUI.Animation.spring(
            response: 0.5,
            dampingFraction: 0.6,
            blendDuration: 0.3
        )
        
        /// Gentle spring for subtle feedback
        static let gentle = SwiftUI.Animation.spring(
            response: 0.3,
            dampingFraction: 0.85,
            blendDuration: 0.1
        )
        
        // MARK: - Specialized Curves
        /// Smooth entry animations
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.25)
        
        /// Dynamic exit animations
        static let easeIn = SwiftUI.Animation.easeIn(duration: 0.2)
        
        /// Smooth bidirectional animations
        static let smooth = SwiftUI.Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.3)
        
        // MARK: - Accessibility-Compliant Alternatives
        /// Fast animation respecting reduced motion
        @MainActor static var fastAccessible: SwiftUI.Animation {
            UIAccessibility.isReduceMotionEnabled ? .easeInOut(duration: 0.1) : fast
        }
        
        /// Spring animation respecting reduced motion
        @MainActor static var springAccessible: SwiftUI.Animation {
            UIAccessibility.isReduceMotionEnabled ? .easeInOut(duration: 0.15) : spring
        }
        
        /// Bounce animation respecting reduced motion
        @MainActor static var bounceAccessible: SwiftUI.Animation {
            UIAccessibility.isReduceMotionEnabled ? .easeInOut(duration: 0.2) : bounce
        }
        
        /// Smooth animation respecting reduced motion
        @MainActor static var smoothAccessible: SwiftUI.Animation {
            UIAccessibility.isReduceMotionEnabled ? .easeInOut(duration: 0.2) : smooth
        }
    }
    
    // MARK: - Accessibility
    
    /// Accessibility-focused design system
    struct Accessibility {
        // Minimum touch target size
        static let minimumTouchTarget: CGFloat = 44
        
        // Dynamic Type scaling factors
        static func scaledFont(_ font: Font) -> Font {
            font
        }
        
        // Semantic labels for common UI elements
        struct Labels {
            static let addPlant = "Add new plant to your collection"
            static let plantCard = "Plant card, double tap to view details"
            static let healthyPlant = "Plant is healthy"
            static let careNeeded = "This plant needs care attention"
            static let wateringOverdue = "Watering is overdue"
            static let fertilizingOverdue = "Fertilizing is overdue"
            static let closeButton = "Close"
            static let backButton = "Go back"
            static let saveButton = "Save changes"
            static let cancelButton = "Cancel action"
            static let editButton = "Edit item"
            static let deleteButton = "Delete item"
        }
        
        // VoiceOver hints
        struct Hints {
            static let plantCard = "Double tap to view plant details and care information"
            static let addPlant = "Opens form to add a new plant to your collection"
            static let careAction = "Tap to record care activity for this plant"
            static let photoButton = "Tap to add or change plant photo"
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standard card styling with enhanced shadows
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.card)
                    .fill(BotanicaTheme.Colors.cardBackground)
                    .shadow(
                        color: BotanicaTheme.Shadows.card,
                        radius: BotanicaTheme.Shadows.cardRadius,
                        x: BotanicaTheme.Shadows.cardOffset.width,
                        y: BotanicaTheme.Shadows.cardOffset.height
                    )
            )
    }
    
    /// Apply hero card styling with elevated shadows
    func heroCardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                    .fill(BotanicaTheme.Gradients.card)
                    .shadow(
                        color: BotanicaTheme.Shadows.hero,
                        radius: BotanicaTheme.Shadows.heroRadius,
                        x: BotanicaTheme.Shadows.heroOffset.width,
                        y: BotanicaTheme.Shadows.heroOffset.height
                    )
            )
    }
    
    /// Apply interactive scaling animation
    func interactiveScale(pressed: Bool) -> some View {
        self
            .scaleEffect(pressed ? 0.96 : 1.0)
            .animation(BotanicaTheme.Animation.fast, value: pressed)
    }
    
    /// Apply standard button styling with gradient background
    func primaryButtonStyle() -> some View {
        self
            .font(BotanicaTheme.Typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, BotanicaTheme.Spacing.lg)
            .padding(.vertical, BotanicaTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.button)
                    .fill(BotanicaTheme.Gradients.primary)
                    .shadow(
                        color: BotanicaTheme.Shadows.button,
                        radius: BotanicaTheme.Shadows.buttonRadius,
                        x: BotanicaTheme.Shadows.buttonOffset.width,
                        y: BotanicaTheme.Shadows.buttonOffset.height
                    )
            )
    }
    
    /// Apply secondary button styling
    func secondaryButtonStyle() -> some View {
        self
            .font(BotanicaTheme.Typography.headline)
            .foregroundColor(BotanicaTheme.Colors.primary)
            .padding(.horizontal, BotanicaTheme.Spacing.lg)
            .padding(.vertical, BotanicaTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.button)
                    .stroke(BotanicaTheme.Colors.primary, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.button)
                            .fill(BotanicaTheme.Colors.surface)
                    )
            )
    }
    
    /// Apply standard section header styling
    func sectionHeader() -> some View {
        self
            .font(BotanicaTheme.Typography.headline)
            .foregroundColor(BotanicaTheme.Colors.primary)
            .padding(.horizontal, BotanicaTheme.Spacing.md)
            .padding(.top, BotanicaTheme.Spacing.lg)
            .padding(.bottom, BotanicaTheme.Spacing.sm)
    }
    
    // MARK: - Accessibility Extensions
    
    /// Apply accessible card styling with semantic information
    func accessibleCardStyle(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .cardStyle()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
    
    /// Ensure minimum touch target size for accessibility
    func minimumTouchTarget() -> some View {
        self
            .frame(minWidth: 44, minHeight: 44) // Apple's minimum recommended size
    }
    
    /// Apply accessible button styling
    func accessibleButton(
        label: String,
        hint: String? = nil,
        role: ButtonRole? = nil
    ) -> some View {
        self
            .minimumTouchTarget()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
    
    /// Apply semantic accessibility for plant health status
    func plantHealthAccessibility(status: HealthStatus) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Plant health: \(status.rawValue)")
            .accessibilityHint(status == .healthy ? "Plant is in good condition" : "This plant needs attention")
    }
    
    /// Apply care indicator accessibility
    func careIndicatorAccessibility(isOverdue: Bool, careType: String) -> some View {
        self
            .accessibilityElement()
            .accessibilityLabel("\(careType) \(isOverdue ? "overdue" : "up to date")")
    }
}
