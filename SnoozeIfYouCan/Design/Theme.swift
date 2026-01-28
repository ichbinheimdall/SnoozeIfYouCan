import SwiftUI

// MARK: - App Design System
// Following Apple Human Interface Guidelines for iOS
// Design tokens: Primary = #FF7A00, CharityPink = #FF2D55

/// Central theme configuration for consistent design language
enum AppTheme {
    
    // MARK: - Brand Colors
    /// Semantic colors that adapt to light/dark mode automatically
    enum Colors {
        // Primary brand color - energetic orange #FF7A00
        static let primary = Color(hex: 0xFF7A00)
        static let primaryGradient = LinearGradient(
            colors: [Color(hex: 0xFF7A00), Color(hex: 0xFF9500)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Charity pink #FF2D55 (Apple's pink)
        static let charityPink = Color(hex: 0xFF2D55)
        static let charityGradient = LinearGradient(
            colors: [Color(hex: 0xFF7A00), Color(hex: 0xFF2D55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Semantic colors
        static let success = Color.green
        static let warning = Color.yellow
        static let error = Color.red
        static let charity = charityPink
        
        // Background layers (Apple-style depth)
        static let backgroundPrimary = Color(.systemBackground)
        static let backgroundSecondary = Color(.secondarySystemBackground)
        static let backgroundTertiary = Color(.tertiarySystemBackground)
        static let backgroundGrouped = Color(.systemGroupedBackground)
        
        // Text hierarchy
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        static let textQuaternary = Color(.quaternaryLabel)
        
        // Separators
        static let separator = Color(.separator)
        static let opaqueSeparator = Color(.opaqueSeparator)
    }
    
    // MARK: - Typography
    /// SF Pro text styles following Apple's type scale
    enum Typography {
        // Large Title - used sparingly, main headers
        static let largeTitle = Font.largeTitle.weight(.bold)
        
        // Time display - alarm clock style
        static let timeDisplay = Font.system(size: 76, weight: .light, design: .rounded)
        static let timeDisplayMedium = Font.system(size: 56, weight: .light, design: .rounded)
        static let timeDisplaySmall = Font.system(size: 42, weight: .light, design: .rounded)
        
        // Standard hierarchy
        static let title1 = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.semibold)
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption1 = Font.caption
        static let caption2 = Font.caption2
        
        // Monospaced for numbers
        static let monospacedDigit = Font.system(.body, design: .rounded).monospacedDigit()
    }
    
    // MARK: - Spacing
    /// Consistent spacing scale (4pt base unit)
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 48
        static let massive: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    /// Consistent corner radius scale
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let circular: CGFloat = .infinity
    }
    
    // MARK: - Shadows
    /// Subtle shadows for depth (Apple-style)
    enum Shadow {
        static let small = ShadowStyle(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        static let medium = ShadowStyle(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        static let large = ShadowStyle(color: .black.opacity(0.16), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Animation
    /// Standard animation curves (Apple-style)
    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        
        // iOS 17+ Modern Spring Animations
        @available(iOS 17.0, *)
        static let snappy = SwiftUI.Animation.spring(duration: 0.3, bounce: 0.2)
        @available(iOS 17.0, *)
        static let gentle = SwiftUI.Animation.spring(duration: 0.5, bounce: 0.15)
        @available(iOS 17.0, *)
        static let expressive = SwiftUI.Animation.spring(duration: 0.6, bounce: 0.3)
        
        /// Returns appropriate animation based on reduce motion preference
        static func adaptive(_ animation: SwiftUI.Animation, reduced: SwiftUI.Animation = .linear(duration: 0)) -> SwiftUI.Animation {
            UIAccessibility.isReduceMotionEnabled ? reduced : animation
        }
    }
    
    // MARK: - Haptic Intensity
    /// Adjustable haptic intensity for accessibility
    enum HapticIntensity {
        case light, medium, heavy
        
        var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light: return .light
            case .medium: return .medium
            case .heavy: return .heavy
            }
        }
    }
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions for Theme

extension View {
    /// Apply card style background
    func cardStyle() -> some View {
        self
            .padding(AppTheme.Spacing.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
    }
    
    /// Animation that respects Reduce Motion setting
    func reduceMotionAnimation<V: Equatable>(
        _ animation: Animation = .default,
        value: V
    ) -> some View {
        self.animation(
            UIAccessibility.isReduceMotionEnabled ? .none : animation,
            value: value
        )
    }
    
    /// Conditional animation based on reduce motion
    func adaptiveAnimation<V: Equatable>(
        standard: Animation,
        reduced: Animation = .easeOut(duration: 0.1),
        value: V
    ) -> some View {
        self.animation(
            UIAccessibility.isReduceMotionEnabled ? reduced : standard,
            value: value
        )
    }
    
    /// Symbol effect that respects reduce motion
    @available(iOS 17.0, *)
    func adaptiveSymbolEffect<T: IndefiniteSymbolEffect & SymbolEffect>(
        _ effect: T,
        isActive: Bool = true
    ) -> some View {
        self.symbolEffect(
            effect,
            options: .nonRepeating,
            isActive: isActive && !UIAccessibility.isReduceMotionEnabled
        )
    }
    
    /// Apply primary button style
    func primaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(AppTheme.Colors.primaryGradient, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }
    
    /// Apply secondary button style
    func secondaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }
    
    /// Apply standard shadow
    func standardShadow() -> some View {
        self.shadow(
            color: AppTheme.Shadow.medium.color,
            radius: AppTheme.Shadow.medium.radius,
            x: AppTheme.Shadow.medium.x,
            y: AppTheme.Shadow.medium.y
        )
    }
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isEnabled ? AppTheme.Colors.primaryGradient : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom))
            }
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(Color.red.gradient, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Preview

#Preview("Theme Colors") {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            Circle().fill(AppTheme.Colors.primary).frame(width: 50)
            Circle().fill(AppTheme.Colors.charityPink).frame(width: 50)
            Circle().fill(AppTheme.Colors.success).frame(width: 50)
            Circle().fill(AppTheme.Colors.warning).frame(width: 50)
            Circle().fill(AppTheme.Colors.error).frame(width: 50)
        }
        
        Text("7:30").font(AppTheme.Typography.timeDisplay)
        
        Button("Primary Button") {}
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
        
        Button("Secondary Button") {}
            .buttonStyle(SecondaryButtonStyle())
            .padding(.horizontal)
    }
    .padding()
}
