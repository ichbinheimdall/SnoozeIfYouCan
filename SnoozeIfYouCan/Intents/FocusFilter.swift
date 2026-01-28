import AppIntents
import SwiftUI
import Combine

// MARK: - Focus Filter
/// Allows users to customize alarm behavior based on Focus mode
/// e.g., "Sleep Focus" could increase snooze costs

@available(iOS 16.0, *)
struct AlarmFocusFilter: SetFocusFilterIntent {
    
    static var title: LocalizedStringResource = "Set Alarm Behavior"
    static var description: IntentDescription? = IntentDescription(
        "Customize how Snooze If You Can behaves during this Focus"
    )
    
    /// Display representation for Focus settings
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "Alarm Behavior",
            subtitle: configurationSummary
        )
    }
    
    private var configurationSummary: LocalizedStringResource {
        if silenceAlarms {
            return "Alarms silenced"
        } else if let multiplier = snoozeCostMultiplier, multiplier != 1.0 {
            return "Snooze cost: \(Int(multiplier * 100))%"
        }
        return "Default behavior"
    }
    
    // MARK: - Parameters
    
    @Parameter(
        title: "Silence Alarms",
        description: "Prevent alarms from making sound during this Focus",
        default: false
    )
    var silenceAlarms: Bool
    
    @Parameter(
        title: "Snooze Cost Multiplier",
        description: "Adjust snooze costs (0.5 = half price, 2.0 = double)",
        default: 1.0,
        controlStyle: .stepper,
        inclusiveRange: (0.5, 3.0)
    )
    var snoozeCostMultiplier: Double?
    
    @Parameter(
        title: "Allow Vibration",
        description: "Allow haptic feedback when alarms trigger",
        default: true
    )
    var allowVibration: Bool
    
    @Parameter(
        title: "Auto-dismiss After",
        description: "Automatically dismiss alarm after this duration (minutes)",
        default: nil,
        inclusiveRange: (1, 30)
    )
    var autoDismissMinutes: Int?
    
    @Parameter(
        title: "Skip Weekend Alarms",
        description: "Don't trigger weekend-only alarms during this Focus",
        default: false
    )
    var skipWeekendAlarms: Bool
    
    // MARK: - Intent Execution
    
    func perform() async throws -> some IntentResult {
        // Save Focus filter settings to UserDefaults/App Storage
        let settings = FocusFilterSettings(
            silenceAlarms: silenceAlarms,
            snoozeCostMultiplier: snoozeCostMultiplier ?? 1.0,
            allowVibration: allowVibration,
            autoDismissMinutes: autoDismissMinutes,
            skipWeekendAlarms: skipWeekendAlarms
        )
        
        await FocusFilterManager.shared.applySettings(settings)
        
        return .result()
    }
}

// MARK: - Focus Filter Settings Model

struct FocusFilterSettings: Codable {
    var silenceAlarms: Bool
    var snoozeCostMultiplier: Double
    var allowVibration: Bool
    var autoDismissMinutes: Int?
    var skipWeekendAlarms: Bool
    
    static let `default` = FocusFilterSettings(
        silenceAlarms: false,
        snoozeCostMultiplier: 1.0,
        allowVibration: true,
        autoDismissMinutes: nil,
        skipWeekendAlarms: false
    )
}

// MARK: - Focus Filter Manager

@MainActor
class FocusFilterManager: ObservableObject {
    static let shared = FocusFilterManager()
    
    @Published private(set) var currentSettings: FocusFilterSettings = .default
    
    private let settingsKey = "focus_filter_settings"
    
    private init() {
        loadSettings()
    }
    
    func applySettings(_ settings: FocusFilterSettings) {
        currentSettings = settings
        saveSettings()
        
        // Notify the app of changes
        NotificationCenter.default.post(
            name: .focusFilterDidChange,
            object: nil,
            userInfo: ["settings": settings]
        )
    }
    
    func resetToDefault() {
        currentSettings = .default
        saveSettings()
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(currentSettings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(FocusFilterSettings.self, from: data) {
            currentSettings = settings
        }
    }
    
    // MARK: - Helpers
    
    /// Get adjusted snooze cost based on Focus filter
    func adjustedSnoozeCost(_ baseCost: Double) -> Double {
        baseCost * currentSettings.snoozeCostMultiplier
    }
    
    /// Check if alarm should be triggered
    func shouldTriggerAlarm(_ alarm: Alarm) -> Bool {
        // Don't trigger if silenced
        if currentSettings.silenceAlarms {
            return false
        }
        
        // Check weekend skip
        if currentSettings.skipWeekendAlarms {
            let weekday = Calendar.current.component(.weekday, from: Date())
            let isWeekend = weekday == 1 || weekday == 7 // Sunday or Saturday
            if isWeekend && (alarm.repeatDays.contains(.saturday) || alarm.repeatDays.contains(.sunday)) {
                return false
            }
        }
        
        return true
    }
    
    /// Check if sound should play
    var shouldPlaySound: Bool {
        !currentSettings.silenceAlarms
    }
    
    /// Check if vibration is allowed
    var shouldVibrate: Bool {
        currentSettings.allowVibration
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let focusFilterDidChange = Notification.Name("focusFilterDidChange")
}

// MARK: - Focus Presets

enum FocusPreset: String, CaseIterable {
    case work = "Work"
    case sleep = "Sleep"
    case personal = "Personal"
    case fitness = "Fitness"
    case driving = "Driving"
    
    var suggestedSettings: FocusFilterSettings {
        switch self {
        case .work:
            return FocusFilterSettings(
                silenceAlarms: false,
                snoozeCostMultiplier: 2.0, // Double cost during work = wake up on time!
                allowVibration: true,
                autoDismissMinutes: nil,
                skipWeekendAlarms: false
            )
        case .sleep:
            return FocusFilterSettings(
                silenceAlarms: false,
                snoozeCostMultiplier: 0.5, // Gentler during sleep wind-down
                allowVibration: true,
                autoDismissMinutes: 15,
                skipWeekendAlarms: false
            )
        case .personal:
            return FocusFilterSettings(
                silenceAlarms: false,
                snoozeCostMultiplier: 1.0,
                allowVibration: true,
                autoDismissMinutes: nil,
                skipWeekendAlarms: true
            )
        case .fitness:
            return FocusFilterSettings(
                silenceAlarms: true, // No alarms during workout
                snoozeCostMultiplier: 1.0,
                allowVibration: false,
                autoDismissMinutes: nil,
                skipWeekendAlarms: false
            )
        case .driving:
            return FocusFilterSettings(
                silenceAlarms: true, // Safety first
                snoozeCostMultiplier: 1.0,
                allowVibration: false,
                autoDismissMinutes: nil,
                skipWeekendAlarms: false
            )
        }
    }
    
    var systemImage: String {
        switch self {
        case .work: return "briefcase.fill"
        case .sleep: return "bed.double.fill"
        case .personal: return "person.fill"
        case .fitness: return "figure.run"
        case .driving: return "car.fill"
        }
    }
}

// MARK: - Focus Settings View

struct FocusSettingsView: View {
    @StateObject private var manager = FocusFilterManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Silence Alarms", isOn: Binding(
                        get: { manager.currentSettings.silenceAlarms },
                        set: { updateSetting(\.silenceAlarms, $0) }
                    ))
                    
                    Toggle("Allow Vibration", isOn: Binding(
                        get: { manager.currentSettings.allowVibration },
                        set: { updateSetting(\.allowVibration, $0) }
                    ))
                    
                    Toggle("Skip Weekend Alarms", isOn: Binding(
                        get: { manager.currentSettings.skipWeekendAlarms },
                        set: { updateSetting(\.skipWeekendAlarms, $0) }
                    ))
                } header: {
                    Text("Alarm Behavior")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Snooze Cost")
                            Spacer()
                            Text("\(Int(manager.currentSettings.snoozeCostMultiplier * 100))%")
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { manager.currentSettings.snoozeCostMultiplier },
                                set: { updateSetting(\.snoozeCostMultiplier, $0) }
                            ),
                            in: 0.5...3.0,
                            step: 0.25
                        )
                        
                        Text("Adjust how much snoozing costs during this Focus")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Pricing")
                }
                
                Section {
                    ForEach(FocusPreset.allCases, id: \.self) { preset in
                        Button {
                            manager.applySettings(preset.suggestedSettings)
                        } label: {
                            HStack {
                                Image(systemName: preset.systemImage)
                                    .frame(width: 30)
                                    .foregroundStyle(.orange)
                                
                                Text(preset.rawValue)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Presets")
                } footer: {
                    Text("Tap a preset to apply suggested settings for that Focus mode")
                }
                
                Section {
                    Button("Reset to Default", role: .destructive) {
                        manager.resetToDefault()
                    }
                }
            }
            .navigationTitle("Focus Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func updateSetting<T>(_ keyPath: WritableKeyPath<FocusFilterSettings, T>, _ value: T) {
        var settings = manager.currentSettings
        settings[keyPath: keyPath] = value
        manager.applySettings(settings)
    }
}

// MARK: - Preview

#Preview("Focus Settings") {
    FocusSettingsView()
}
