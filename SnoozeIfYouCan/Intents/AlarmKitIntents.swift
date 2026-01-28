import AppIntents
import Foundation

#if canImport(AlarmKit)
import AlarmKit
#endif

// MARK: - Stop Alarm Intent

/// AppIntent that handles stopping an alarm from the AlarmKit UI
/// Conforms to LiveActivityIntent for use with AlarmKit presentation
@available(iOS 26.0, *)
struct StopAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Alarm"
    static var description = IntentDescription("Stop the alarm and wake up")
    
    @Parameter(title: "Alarm ID")
    var alarmID: String
    
    init() {
        self.alarmID = ""
    }
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else {
            return .result()
        }
        
        // Stop the alarm via AlarmKit
        AlarmKitService.shared.stopAlarm(id: uuid)
        
        // Dismiss in our app's alarm manager
        let alarmManager = AlarmManager()
        if let alarm = alarmManager.alarms.first(where: { $0.id == uuid }) {
            alarmManager.dismissAlarm(alarm)
            
            // Update streak stats
            alarmManager.stats.currentStreak += 1
            if alarmManager.stats.currentStreak > alarmManager.stats.longestStreak {
                alarmManager.stats.longestStreak = alarmManager.stats.currentStreak
            }
        }
        
        // Play haptic feedback
        HapticsManager.shared.wakeUpSuccess()
        
        return .result()
    }
}

// MARK: - Snooze Alarm Intent

/// AppIntent that handles snoozing an alarm from the AlarmKit UI
/// This triggers the donation flow for the "Snooze If You Can" mechanic
/// Conforms to LiveActivityIntent for use with AlarmKit presentation
@available(iOS 26.0, *)
struct SnoozeAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Snooze Alarm"
    static var description = IntentDescription("Snooze the alarm and donate to charity")
    
    @Parameter(title: "Alarm ID")
    var alarmID: String
    
    @Parameter(title: "Snooze Cost")
    var cost: Double
    
    init() {
        self.alarmID = ""
        self.cost = 1.0
    }
    
    init(alarmID: String, cost: Double) {
        self.alarmID = alarmID
        self.cost = cost
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: alarmID) else {
            return .result(dialog: "Invalid alarm ID")
        }
        
        let alarmManager = AlarmManager()
        
        guard let alarm = alarmManager.alarms.first(where: { $0.id == uuid }) else {
            return .result(dialog: "Alarm not found")
        }
        
        // Check if max snoozes reached
        if alarmManager.hasReachedMaxSnoozes(alarm) {
            return .result(dialog: "Maximum snoozes reached! Time to wake up! ☀️")
        }
        
        // Process the snooze donation
        let paidCost = alarmManager.snoozeAlarm(alarm)
        
        // Trigger snooze countdown via AlarmKit
        AlarmKitService.shared.snoozeAlarm(id: uuid)
        
        // Play feedback
        HapticsManager.shared.snoozeConfirm()
        SoundManager.shared.playSnoozeSound()
        
        return .result(
            dialog: "Snoozed! 💤 $\(String(format: "%.2f", paidCost)) donated to Darüşşafaka. See you in 9 minutes!"
        )
    }
}

// MARK: - Pause Alarm Intent

/// AppIntent to pause a countdown alarm
@available(iOS 26.0, *)
struct PauseAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Alarm"
    static var description = IntentDescription("Pause the alarm countdown")
    
    @Parameter(title: "Alarm ID")
    var alarmID: String
    
    init() {
        self.alarmID = ""
    }
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else {
            return .result()
        }
        
        AlarmKitService.shared.pauseAlarm(id: uuid)
        return .result()
    }
}

// MARK: - Resume Alarm Intent

/// AppIntent to resume a paused alarm
@available(iOS 26.0, *)
struct ResumeAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume Alarm"
    static var description = IntentDescription("Resume the paused alarm")
    
    @Parameter(title: "Alarm ID")
    var alarmID: String
    
    init() {
        self.alarmID = ""
    }
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else {
            return .result()
        }
        
        AlarmKitService.shared.resumeAlarm(id: uuid)
        return .result()
    }
}

// MARK: - Quick Alarm Intent

/// AppIntent to quickly set a timer/alarm from Siri or Shortcuts
@available(iOS 26.0, *)
struct QuickAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Quick Alarm"
    static var description = IntentDescription("Set a quick alarm with donation snooze")
    
    @Parameter(title: "Minutes", description: "Minutes until alarm")
    var minutes: Int
    
    @Parameter(title: "Snooze Cost", description: "Cost to snooze", default: 1.0)
    var snoozeCost: Double
    
    static var parameterSummary: some ParameterSummary {
        Summary("Set alarm for \(\.$minutes) minutes") {
            \.$snoozeCost
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let alarmTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        
        let alarm = Alarm(
            time: alarmTime,
            label: "Quick Alarm",
            snoozeCost: snoozeCost
        )
        
        let alarmManager = AlarmManager()
        alarmManager.addAlarm(alarm)
        
        // Schedule with AlarmKit
        do {
            try await AlarmKitService.shared.scheduleAlarm(alarm)
        } catch {
            return .result(dialog: "Failed to schedule alarm: \(error.localizedDescription)")
        }
        
        return .result(
            dialog: "Alarm set for \(minutes) minute\(minutes == 1 ? "" : "s"). Snoozing costs $\(String(format: "%.2f", snoozeCost)) for charity! 💤"
        )
    }
}

// MARK: - Cancel Alarm Intent

/// AppIntent to cancel an alarm
@available(iOS 26.0, *)
struct CancelAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Cancel Alarm"
    static var description = IntentDescription("Cancel a scheduled alarm")
    
    @Parameter(title: "Alarm ID")
    var alarmID: String?
    
    init() {
        self.alarmID = nil
    }
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let alarmManager = AlarmManager()
        
        if let alarmID = alarmID, let uuid = UUID(uuidString: alarmID) {
            // Cancel specific alarm
            if let alarm = alarmManager.alarms.first(where: { $0.id == uuid }) {
                alarmManager.deleteAlarm(alarm)
                AlarmKitService.shared.cancelAlarm(id: uuid)
                return .result(dialog: "Alarm cancelled")
            }
        } else {
            // Cancel next alarm
            if let nextAlarm = alarmManager.alarms.filter({ $0.isEnabled }).sorted(by: { $0.time < $1.time }).first {
                alarmManager.deleteAlarm(nextAlarm)
                AlarmKitService.shared.cancelAlarm(nextAlarm)
                return .result(dialog: "Cancelled your next alarm at \(nextAlarm.timeString)")
            }
        }
        
        return .result(dialog: "No alarm found to cancel")
    }
}
