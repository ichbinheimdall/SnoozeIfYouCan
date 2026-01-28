import SwiftUI

// MARK: - Accessibility Modifiers
// Following Apple HIG for Accessibility

extension View {
    /// Add comprehensive accessibility to alarm rows
    func alarmAccessibility(
        time: String,
        label: String,
        isEnabled: Bool,
        repeatDays: String,
        snoozeCost: Double
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(time), \(label.isEmpty ? "Alarm" : label)")
            .accessibilityValue(isEnabled ? "Enabled, \(repeatDays)" : "Disabled")
            .accessibilityHint("Snooze costs \(String(format: "%.2f", snoozeCost)) dollars. Double tap to edit.")
            .accessibilityAddTraits(isEnabled ? [] : .isButton)
    }
    
    /// Add accessibility to stat cards
    func statCardAccessibility(title: String, value: String) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title)")
            .accessibilityValue(value)
    }
    
    /// Add accessibility to achievement badges
    func achievementAccessibility(title: String, isUnlocked: Bool, description: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title) achievement")
            .accessibilityValue(isUnlocked ? "Unlocked" : "Locked")
            .accessibilityHint(description)
    }
}

// MARK: - Accessibility Announcements

@MainActor
class AccessibilityAnnouncer {
    static let shared = AccessibilityAnnouncer()
    
    private init() {}
    
    /// Announce alarm state changes
    func announceAlarmToggled(isEnabled: Bool, time: String) {
        let message = isEnabled 
            ? "Alarm at \(time) enabled"
            : "Alarm at \(time) disabled"
        announce(message)
    }
    
    /// Announce snooze action
    func announceSnooze(cost: Double, minutesRemaining: Int) {
        let message = "Snoozed for \(String(format: "%.2f", cost)) dollars. \(minutesRemaining) minutes until next alarm."
        announce(message)
    }
    
    /// Announce alarm dismissed
    func announceAlarmDismissed(streakCount: Int) {
        let message = streakCount > 0
            ? "Alarm dismissed. Great job! Your streak is now \(streakCount) days."
            : "Alarm dismissed. Good morning!"
        announce(message)
    }
    
    /// Announce achievement unlocked
    func announceAchievementUnlocked(_ achievement: Achievement) {
        let message = "Achievement unlocked: \(achievement.title). \(achievement.description)"
        announce(message)
    }
    
    /// Announce payment success
    func announcePaymentSuccess(amount: Double) {
        let message = "Payment successful. \(String(format: "%.2f", amount)) dollars donated to Darüşşafaka."
        announce(message)
    }
    
    private func announce(_ message: String) {
        // Post accessibility notification
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

// MARK: - Accessibility Environment Values

private struct AccessibilityReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var accessibilityReduceMotion: Bool {
        get { self[AccessibilityReduceMotionKey.self] }
        set { self[AccessibilityReduceMotionKey.self] = newValue }
    }
}

// MARK: - Accessible Time Picker

/// Custom time picker with improved VoiceOver support
struct AccessibleTimePicker: View {
    @Binding var time: Date
    @Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled
    
    var body: some View {
        if voiceOverEnabled {
            // More accessible date picker for VoiceOver users
            VStack(spacing: AppTheme.Spacing.lg) {
                // Hour picker
                Picker("Hour", selection: hourBinding) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour)")
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 100)
                .accessibilityLabel("Hour")
                
                // Minute picker
                Picker("Minute", selection: minuteBinding) {
                    ForEach(0..<60, id: \.self) { minute in
                        Text(String(format: "%02d", minute))
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 100)
                .accessibilityLabel("Minute")
            }
        } else {
            // Standard date picker for sighted users
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
        }
    }
    
    private var hourBinding: Binding<Int> {
        Binding(
            get: { Calendar.current.component(.hour, from: time) },
            set: { newHour in
                let minute = Calendar.current.component(.minute, from: time)
                if let newTime = Calendar.current.date(bySettingHour: newHour, minute: minute, second: 0, of: time) {
                    time = newTime
                }
            }
        )
    }
    
    private var minuteBinding: Binding<Int> {
        Binding(
            get: { Calendar.current.component(.minute, from: time) },
            set: { newMinute in
                let hour = Calendar.current.component(.hour, from: time)
                if let newTime = Calendar.current.date(bySettingHour: hour, minute: newMinute, second: 0, of: time) {
                    time = newTime
                }
            }
        )
    }
}

// MARK: - Accessible Button Styles

/// Large touch target button for accessibility
struct AccessibleButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 44, minHeight: 44) // Minimum touch target per Apple HIG
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
    }
}

// MARK: - Dynamic Type Support

extension Font {
    /// Scales with Dynamic Type while maintaining hierarchy
    static func scaledTitle() -> Font {
        .system(.title, design: .rounded, weight: .bold)
    }
    
    static func scaledHeadline() -> Font {
        .system(.headline, design: .rounded, weight: .semibold)
    }
    
    static func scaledBody() -> Font {
        .system(.body, design: .default, weight: .regular)
    }
    
    static func scaledCaption() -> Font {
        .system(.caption, design: .default, weight: .regular)
    }
}

// MARK: - Reduce Motion Support

struct ReduceMotionWrapper<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let standardContent: Content
    let reducedContent: Content
    
    init(
        @ViewBuilder standard: () -> Content,
        @ViewBuilder reduced: () -> Content
    ) {
        self.standardContent = standard()
        self.reducedContent = reduced()
    }
    
    var body: some View {
        if reduceMotion {
            reducedContent
        } else {
            standardContent
        }
    }
}

// MARK: - High Contrast Support

extension Color {
    /// Returns a high-contrast version of the color when needed
    func highContrastVariant(for colorScheme: ColorScheme) -> Color {
        // In a real app, return specific high-contrast colors
        self
    }
}

// MARK: - Accessibility Labels for Common Actions

enum AccessibilityLabels {
    static let addAlarm = "Add new alarm"
    static let editAlarm = "Edit alarm"
    static let deleteAlarm = "Delete alarm"
    static let toggleAlarm = "Toggle alarm on or off"
    static let snoozeAlarm = "Snooze alarm and donate"
    static let dismissAlarm = "Dismiss alarm, I'm awake"
    static let playSound = "Preview alarm sound"
    static let stopSound = "Stop sound preview"
    
    static func alarmTime(_ time: String) -> String {
        "Alarm set for \(time)"
    }
    
    static func snoozeCost(_ cost: Double) -> String {
        "Snooze costs \(String(format: "%.2f", cost)) dollars"
    }
    
    static func streakCount(_ count: Int) -> String {
        "\(count) day wake-up streak"
    }
    
    static func donationTotal(_ amount: Double) -> String {
        "\(String(format: "%.2f", amount)) dollars donated to Darüşşafaka"
    }
}

// MARK: - Preview

#Preview("Accessible Time Picker") {
    struct PreviewWrapper: View {
        @State private var time = Date()
        
        var body: some View {
            AccessibleTimePicker(time: $time)
        }
    }
    
    return PreviewWrapper()
}
