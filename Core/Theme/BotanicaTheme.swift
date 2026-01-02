import SwiftUI
import UIKit

/// Botanica's design system providing colors, typography, and spacing constants
/// following iOS design guidelines and botanical aesthetics
struct BotanicaTheme {
    
    // MARK: - Colors
    
    /// Semantic color palette following iOS 26 design principles with botanical inspiration
    struct Colors {
        private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
            Color(UIColor { trait in
                trait.userInterfaceStyle == .dark ? dark : light
            })
        }

        // Primary brand colors - refined for better contrast and vibrancy
        static let leafGreen = Color(red: 0.176, green: 0.745, blue: 0.376)    // Accent green
        static let forestGreen = Color(red: 0.11, green: 0.58, blue: 0.15)    // Deeper, richer
        static let mintGreen = Color(red: 0.55, green: 0.94, blue: 0.62)      // Softer mint
        
        // Earth tones refined for modern UI
        static let soilBrown = Color(red: 0.48, green: 0.35, blue: 0.22)      // Warmer, more sophisticated
        static let terracotta = Color(red: 0.82, green: 0.49, blue: 0.25)     // More vibrant
        static let creamWhite = Color(red: 0.98, green: 0.97, blue: 0.94)     // Subtle warmth
        
        // Care-specific colors with enhanced accessibility
        static let waterBlue = Color(red: 0.231, green: 0.510, blue: 0.965)   // Info blue
        static let sunYellow = Color(red: 0.961, green: 0.647, blue: 0.141)   // Warning tone
        static let nutrientOrange = Color(red: 0.96, green: 0.57, blue: 0.18) // Better contrast
        
        // System integration colors
        static let primary = leafGreen
        static let secondary = forestGreen
        static let accent = leafGreen
        static let accentWeak = dynamicColor(
            light: UIColor(red: 0.902, green: 0.969, blue: 0.929, alpha: 1.0),
            dark: UIColor(red: 0.106, green: 0.227, blue: 0.149, alpha: 1.0)
        )
        static let background = dynamicColor(
            light: UIColor(red: 0.965, green: 0.969, blue: 0.973, alpha: 1.0),
            dark: UIColor(red: 0.047, green: 0.047, blue: 0.055, alpha: 1.0)
        )
        static let surface = dynamicColor(
            light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            dark: UIColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 1.0)
        )
        static let surfaceAlt = dynamicColor(
            light: UIColor(red: 0.941, green: 0.949, blue: 0.953, alpha: 1.0),
            dark: UIColor(red: 0.165, green: 0.165, blue: 0.180, alpha: 1.0)
        )
        static let cardBackground = surfaceAlt
        static let border = dynamicColor(
            light: UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1.0),
            dark: UIColor(red: 0.184, green: 0.184, blue: 0.204, alpha: 1.0)
        )
        
        // Status colors optimized for clarity
        static let success = Color(red: 0.176, green: 0.745, blue: 0.376)
        static let warning = Color(red: 0.961, green: 0.647, blue: 0.141)
        static let error = Color(red: 0.890, green: 0.302, blue: 0.302)
        static let info = waterBlue
        
        // Text colors for optimal legibility
        static let textPrimary = dynamicColor(
            light: UIColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 1.0),
            dark: UIColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1.0)
        )
        static let textSecondary = dynamicColor(
            light: UIColor(red: 0.420, green: 0.447, blue: 0.502, alpha: 1.0),
            dark: UIColor(red: 0.631, green: 0.631, blue: 0.667, alpha: 1.0)
        )
        static let textTertiary = dynamicColor(
            light: UIColor(red: 0.612, green: 0.639, blue: 0.686, alpha: 1.0),
            dark: UIColor(red: 0.443, green: 0.443, blue: 0.478, alpha: 1.0)
        )
        
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
        static let largeTitle = Font.system(size: 28, weight: .semibold)
        static let display = Font.system(size: 28, weight: .semibold)
        
        /// Title 1 for primary section headers
        static let title1 = Font.system(size: 24, weight: .semibold)
        
        /// Title 2 for secondary section headers
        static let title2 = Font.system(size: 20, weight: .semibold)
        
        /// Title 3 for tertiary headers
        static let title3 = Font.system(size: 17, weight: .medium)

        /// Title 4 for compact headers
        static let title4 = Font.system(size: 22, weight: .semibold)

        /// Compact headline for dense content
        static let headlineSmall = Font.system(size: 16, weight: .semibold)
        
        // MARK: - Body Hierarchy
        /// Headline for important content
        static let headline = Font.system(size: 17, weight: .semibold)
        
        /// Larger headline for emphasis
        static let headlineLarge = Font.system(size: 18, weight: .semibold)
        
        /// Subheadline for secondary content
        static let subheadline = Font.system(size: 15, weight: .medium)
        
        /// Body text for primary content
        static let body = Font.system(size: 15, weight: .regular)

        /// Body emphasized for important body text
        static let bodyEmphasized = Font.system(size: 15, weight: .medium)

        /// Larger body text for list rows
        static let bodyLarge = Font.system(size: 16, weight: .regular)
        static let bodyLargeEmphasized = Font.system(size: 16, weight: .medium)
        
        /// Callout for emphasized content
        static let callout = Font.system(size: 13, weight: .medium)
        static let bodySmall = Font.system(size: 13, weight: .regular)
        static let calloutEmphasized = Font.system(size: 13, weight: .semibold)
        
        /// Label text for compact UI
        static let label = Font.system(size: 14, weight: .regular)
        static let labelEmphasized = Font.system(size: 14, weight: .semibold)
        
        // MARK: - Supporting Text
        /// Footnote for supplementary information
        static let footnote = Font.system(size: 12, weight: .regular)

        /// Caption 1 for metadata and labels
        static let caption = Font.system(size: 12, weight: .regular)
        static let captionEmphasized = Font.system(size: 12, weight: .semibold)
        
        /// Caption 2 for the smallest text
        static let caption2 = Font.system(size: 11, weight: .regular)
        static let micro = Font.system(size: 11, weight: .regular)
        static let caption2Emphasized = Font.system(size: 11, weight: .semibold)
        static let nano = Font.system(size: 10, weight: .regular)
        
        // MARK: - Interactive Elements
        /// Button text with proper emphasis
        static let button = Font.system(size: 15, weight: .semibold)
        
        /// Navigation text
        static let navigation = Font.system(size: 12, weight: .medium)
        
        /// Tab bar text
        static let tabBar = Font.system(size: 11, weight: .medium)
        
        // MARK: - Specialized
        /// Scientific names use elegant italic styling
        static let scientificName = Font.system(size: 13, weight: .regular).italic()
        
        /// Large scientific names for headers
        static let scientificNameLarge = Font.system(size: 17, weight: .regular).italic()
        
        /// Numbers and statistics
        static let numeric = Font.system(size: 15, weight: .medium).monospacedDigit()
        static let statValue = Font.system(size: 24, weight: .bold, design: .rounded)
    }
    
    // MARK: - Spacing
    
    /// iOS 26-compliant spacing system using 4pt base grid
    struct Spacing {
        static let xxs: CGFloat = 2       // Micro spacing
        static let xs: CGFloat = 4        // Tight spacing
        static let sm: CGFloat = 8        // Small spacing
        static let smPlus: CGFloat = 12   // Small-plus spacing
        static let md: CGFloat = 16       // Standard spacing
        static let mdPlus: CGFloat = 20   // Screen padding
        static let lg: CGFloat = 24       // Large spacing
        static let xl: CGFloat = 32       // Extra large
        static let xxl: CGFloat = 48      // Maximum spacing
        static let jumbo: CGFloat = 64    // Hero sections

        // Semantic spacing
        static let inline: CGFloat = 8
        static let item: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let screenPadding: CGFloat = 20
        static let section: CGFloat = 24
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
        static let chip: CGFloat = 18
        static let fab: CGFloat = 28
        static let buttonLarge: CGFloat = 14
        
        // Semantic radius
        static let card = large
        static let button = buttonLarge
        static let modal = large
    }

    // MARK: - Sizing

    struct Sizing {
        static let primaryButtonHeight: CGFloat = 48
        static let secondaryButtonHeight: CGFloat = 44
        static let chipHeight: CGFloat = 36
        static let fabSize: CGFloat = 56
        static let iconInline: CGFloat = 20
        static let iconPrimary: CGFloat = 24
        static let iconSmall: CGFloat = 18
        static let iconLarge: CGFloat = 28
        static let iconLargePlus: CGFloat = 32
        static let iconXL: CGFloat = 36
        static let iconXXXL: CGFloat = 40
        static let iconXXL: CGFloat = 48
        static let iconFeature: CGFloat = 50
        static let iconHero: CGFloat = 52
        static let iconStatus: CGFloat = 56
        static let iconJumbo: CGFloat = 60
        static let iconMega: CGFloat = 80
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
            .font(BotanicaTheme.Typography.button)
            .foregroundColor(.white)
            .padding(.horizontal, BotanicaTheme.Spacing.lg)
            .padding(.vertical, BotanicaTheme.Spacing.md)
            .frame(minHeight: BotanicaTheme.Sizing.primaryButtonHeight)
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
            .font(BotanicaTheme.Typography.button)
            .foregroundColor(BotanicaTheme.Colors.primary)
            .padding(.horizontal, BotanicaTheme.Spacing.lg)
            .padding(.vertical, BotanicaTheme.Spacing.md)
            .frame(minHeight: BotanicaTheme.Sizing.secondaryButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.button)
                    .stroke(BotanicaTheme.Colors.primary, lineWidth: 1)
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
