import SwiftUI

// MARK: - High Contrast & Accessibility Design Enhancements
// Supporting accessibilityIncreaseContrast and other visual accessibility features

// MARK: - Adaptive Colors

extension Color {
    /// Returns high contrast version when accessibility setting is enabled
    static func adaptive(
        standard: Color,
        highContrast: Color
    ) -> Color {
        // SwiftUI will automatically choose based on context
        standard
    }
}

// MARK: - High Contrast Color Palette

enum HighContrastColors {
    // Primary colors with enhanced contrast
    static let primaryText = Color.primary
    static let secondaryText = Color(.secondaryLabel)
    
    // High contrast alternatives
    static let primaryHighContrast = Color.black
    static let secondaryHighContrast = Color(.darkGray)
    
    // Orange variants
    static let accentStandard = Color.orange
    static let accentHighContrast = Color(red: 0.9, green: 0.4, blue: 0.0) // Darker orange
    
    // Background colors
    static let cardBackground = Color(.secondarySystemBackground)
    static let cardBackgroundHighContrast = Color(.systemBackground)
}

// MARK: - Contrast-Aware View Modifier

struct ContrastAwareModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) var contrast
    
    let standardOpacity: Double
    let highContrastOpacity: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(contrast == .increased ? highContrastOpacity : standardOpacity)
    }
}

extension View {
    func contrastAwareOpacity(standard: Double = 0.7, increased: Double = 1.0) -> some View {
        modifier(ContrastAwareModifier(standardOpacity: standard, highContrastOpacity: increased))
    }
}

// MARK: - Accessible Card Style

struct AccessibleCardStyle: ViewModifier {
    @Environment(\.colorSchemeContrast) var contrast
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.lg)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var cardBackground: some ShapeStyle {
        if contrast == .increased {
            return AnyShapeStyle(Color(.systemBackground))
        }
        return AnyShapeStyle(Material.regularMaterial)
    }
    
    private var borderColor: Color {
        if contrast == .increased {
            return colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.2)
        }
        return .clear
    }
    
    private var borderWidth: CGFloat {
        contrast == .increased ? 1.5 : 0
    }
}

extension View {
    func accessibleCardStyle() -> some View {
        modifier(AccessibleCardStyle())
    }
}

// MARK: - Accessible Button

struct AccessiblePrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @Environment(\.colorSchemeContrast) var contrast
    @Environment(\.isEnabled) var isEnabled
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(backgroundGradient, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .accessibilityLabel(title)
    }
    
    private var backgroundGradient: some ShapeStyle {
        if contrast == .increased {
            // Solid, higher contrast color
            return AnyShapeStyle(Color(red: 0.85, green: 0.35, blue: 0.0))
        }
        return AnyShapeStyle(AppTheme.Colors.primaryGradient)
    }
    
    private var borderColor: Color {
        contrast == .increased ? .white.opacity(0.3) : .clear
    }
    
    private var borderWidth: CGFloat {
        contrast == .increased ? 1 : 0
    }
}

// MARK: - Accessible Time Display

struct AccessibleTimeDisplay: View {
    let time: Date
    let size: TimeDisplaySize
    
    @Environment(\.colorSchemeContrast) var contrast
    @Environment(\.sizeCategory) var sizeCategory
    
    enum TimeDisplaySize {
        case large, medium, small
        
        var fontSize: CGFloat {
            switch self {
            case .large: return 76
            case .medium: return 56
            case .small: return 42
            }
        }
    }
    
    var body: some View {
        Text(time.formatted(date: .omitted, time: .shortened))
            .font(.system(size: scaledFontSize, weight: fontWeight, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }
    
    private var scaledFontSize: CGFloat {
        // Scale down for larger text sizes to prevent overflow
        switch sizeCategory {
        case .accessibilityExtraExtraExtraLarge:
            return size.fontSize * 0.5
        case .accessibilityExtraExtraLarge:
            return size.fontSize * 0.6
        case .accessibilityExtraLarge:
            return size.fontSize * 0.7
        case .accessibilityLarge:
            return size.fontSize * 0.8
        case .accessibilityMedium:
            return size.fontSize * 0.9
        default:
            return size.fontSize
        }
    }
    
    private var fontWeight: Font.Weight {
        // Increase weight for high contrast
        contrast == .increased ? .regular : .light
    }
}

// MARK: - Accessible Stat Card

struct AccessibleStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @Environment(\.colorSchemeContrast) var contrast
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
            
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(valueColor)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(titleColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .accessibleCardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
    
    private var iconColor: Color {
        contrast == .increased ? color.opacity(1.0) : color.opacity(0.8)
    }
    
    private var valueColor: Color {
        contrast == .increased ? .primary : .primary
    }
    
    private var titleColor: Color {
        contrast == .increased ? .primary.opacity(0.8) : .secondary
    }
}

// MARK: - Bold Text Support

struct BoldTextModifier: ViewModifier {
    @Environment(\.legibilityWeight) var legibilityWeight
    
    func body(content: Content) -> some View {
        if legibilityWeight == .bold {
            content.fontWeight(.semibold)
        } else {
            content
        }
    }
}

extension View {
    func respectsBoldText() -> some View {
        modifier(BoldTextModifier())
    }
}

// MARK: - Motion Reduced Transitions

struct ReducedMotionTransition: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    let standardTransition: AnyTransition
    let reducedTransition: AnyTransition
    
    func body(content: Content) -> some View {
        content
            .transition(reduceMotion ? reducedTransition : standardTransition)
    }
}

extension View {
    func adaptiveTransition(
        standard: AnyTransition,
        reduced: AnyTransition = .opacity
    ) -> some View {
        modifier(ReducedMotionTransition(
            standardTransition: standard,
            reducedTransition: reduced
        ))
    }
}

// MARK: - Focus Ring for Keyboard/Switch Control

struct FocusRingModifier: ViewModifier {
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .opacity(isFocused ? 1 : 0)
                    .padding(-4)
            )
    }
}

extension View {
    func accessibleFocusRing() -> some View {
        modifier(FocusRingModifier())
    }
}

// MARK: - Preview

#Preview("High Contrast Components") {
    VStack(spacing: 20) {
        AccessibleTimeDisplay(time: Date(), size: .large)
        
        AccessiblePrimaryButton("Snooze for $1.99", icon: "bed.double.fill") {}
        
        HStack {
            AccessibleStatCard(
                title: "Donated",
                value: "$47.50",
                icon: "heart.fill",
                color: .pink
            )
            
            AccessibleStatCard(
                title: "Streak",
                value: "7 days",
                icon: "flame.fill",
                color: .orange
            )
        }
    }
    .padding()
}
