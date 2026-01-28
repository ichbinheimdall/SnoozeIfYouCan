import AppIntents
import Foundation

// MARK: - App Shortcuts Provider
/// Defines all Siri Shortcuts available for the app
@available(iOS 16.0, *)
struct AlarmShortcuts: AppShortcutsProvider {
    
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateAlarmIntent(),
            phrases: [
                "Create alarm in \(.applicationName)",
                "Set an alarm in \(.applicationName)",
                "Add alarm to \(.applicationName)",
                "Wake me up with \(.applicationName)"
            ],
            shortTitle: "Create Alarm",
            systemImageName: "alarm.fill"
        )
        
        AppShortcut(
            intent: ViewDonationsIntent(),
            phrases: [
                "Show my donations in \(.applicationName)",
                "How much have I donated with \(.applicationName)",
                "Check my impact in \(.applicationName)"
            ],
            shortTitle: "View Donations",
            systemImageName: "heart.fill"
        )
        
        AppShortcut(
            intent: GetStreakIntent(),
            phrases: [
                "What's my wake up streak in \(.applicationName)",
                "Show my streak in \(.applicationName)",
                "How many days in a row in \(.applicationName)"
            ],
            shortTitle: "Check Streak",
            systemImageName: "flame.fill"
        )
        
        AppShortcut(
            intent: GetNextAlarmIntent(),
            phrases: [
                "When is my next alarm in \(.applicationName)",
                "What time is my alarm in \(.applicationName)",
                "Next alarm in \(.applicationName)"
            ],
            shortTitle: "Next Alarm",
            systemImageName: "clock.fill"
        )
    }
}

// MARK: - Create Alarm Intent

@available(iOS 16.0, *)
struct CreateAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Alarm"
    static var description = IntentDescription("Create a new alarm with snooze donation")
    
    @Parameter(title: "Time", description: "What time should the alarm go off?")
    var time: Date
    
    @Parameter(title: "Label", description: "Optional label for the alarm", default: "")
    var label: String
    
    @Parameter(title: "Snooze Cost", description: "Cost in USD to snooze", default: 1.0)
    var snoozeCost: Double
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create alarm for \(\.$time)") {
            \.$label
            \.$snoozeCost
        }
    }
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let alarm = Alarm(
            time: time,
            label: label,
            snoozeCost: snoozeCost
        )
        
        // Access shared alarm manager through app storage
        let alarmManager = AlarmManager()
        alarmManager.addAlarm(alarm)
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timeString = timeFormatter.string(from: time)
        
        return .result(
            dialog: "Created alarm for \(timeString). Snoozing will cost $\(String(format: "%.2f", snoozeCost)) for charity."
        ) {
            AlarmCreatedSnippetView(time: timeString, cost: snoozeCost)
        }
    }
}

// MARK: - View Donations Intent

@available(iOS 16.0, *)
struct ViewDonationsIntent: AppIntent {
    static var title: LocalizedStringResource = "View Donations"
    static var description = IntentDescription("See how much you've donated to Darüşşafaka")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let alarmManager = AlarmManager()
        let total = alarmManager.stats.totalDonated
        let snoozes = alarmManager.stats.totalSnoozes
        
        return .result(
            dialog: "You've donated $\(String(format: "%.2f", total)) to Darüşşafaka through \(snoozes) snoozes!"
        ) {
            DonationSnippetView(total: total, snoozes: snoozes)
        }
    }
}

// MARK: - Get Streak Intent

@available(iOS 16.0, *)
struct GetStreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Wake-up Streak"
    static var description = IntentDescription("See your current no-snooze streak")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let alarmManager = AlarmManager()
        let streak = alarmManager.stats.currentStreak
        
        if streak > 0 {
            return .result(dialog: "Amazing! You're on a \(streak)-day wake-up streak! 🔥")
        } else {
            return .result(dialog: "Start your streak tomorrow by dismissing your alarm without snoozing!")
        }
    }
}

// MARK: - Get Next Alarm Intent

@available(iOS 16.0, *)
struct GetNextAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Alarm"
    static var description = IntentDescription("Find out when your next alarm is set")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let alarmManager = AlarmManager()
        
        let activeAlarms = alarmManager.alarms
            .filter { $0.isEnabled }
            .sorted { $0.time < $1.time }
        
        guard let nextAlarm = activeAlarms.first else {
            return .result(dialog: "You don't have any alarms set. Would you like to create one?")
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timeString = timeFormatter.string(from: nextAlarm.time)
        
        let label = nextAlarm.label.isEmpty ? "" : " (\(nextAlarm.label))"
        
        return .result(dialog: "Your next alarm is at \(timeString)\(label). Snoozing costs $\(String(format: "%.2f", nextAlarm.snoozeCost)).")
    }
}

// MARK: - Toggle All Alarms Intent

@available(iOS 16.0, *)
struct ToggleAllAlarmsIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle All Alarms"
    static var description = IntentDescription("Enable or disable all alarms at once")
    
    @Parameter(title: "Enable", description: "Turn alarms on or off")
    var enable: Bool
    
    static var parameterSummary: some ParameterSummary {
        When(\.$enable, .equalTo, true) {
            Summary("Enable all alarms")
        } otherwise: {
            Summary("Disable all alarms")
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let alarmManager = AlarmManager()
        let count = alarmManager.alarms.count
        
        for i in 0..<alarmManager.alarms.count {
            alarmManager.alarms[i].isEnabled = enable
        }
        
        if enable {
            return .result(dialog: "Enabled \(count) alarm\(count == 1 ? "" : "s"). Time to wake up with purpose!")
        } else {
            return .result(dialog: "Disabled \(count) alarm\(count == 1 ? "" : "s"). Enjoy your rest!")
        }
    }
}

// MARK: - Snippet Views

import SwiftUI

@available(iOS 16.0, *)
struct AlarmCreatedSnippetView: View {
    let time: String
    let cost: Double
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "alarm.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(time)
                    .font(.title2.bold())
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.pink)
                    Text("Snooze: $\(String(format: "%.2f", cost))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(.green)
        }
        .padding()
    }
}

@available(iOS 16.0, *)
struct DonationSnippetView: View {
    let total: Double
    let snoozes: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                Text("Darüşşafaka Donations")
                    .font(.headline)
            }
            
            Text("$\(String(format: "%.2f", total))")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
            
            Text("\(snoozes) snooze\(snoozes == 1 ? "" : "s") converted to impact")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Preview

@available(iOS 16.0, *)
#Preview("Alarm Created Snippet") {
    AlarmCreatedSnippetView(time: "7:30 AM", cost: 1.99)
}

@available(iOS 16.0, *)
#Preview("Donation Snippet") {
    DonationSnippetView(total: 47.50, snoozes: 32)
}
