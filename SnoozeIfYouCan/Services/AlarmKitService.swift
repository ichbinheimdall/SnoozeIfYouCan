import Foundation
import SwiftUI
import Combine
import AlarmKit
import ActivityKit

// MARK: - AlarmKit Metadata

/// Custom metadata for SnoozeIfYouCan alarms
/// Contains donation/snooze-specific information
@available(iOS 26.0, *)
struct SnoozeAlarmMetadata: AlarmMetadata {
    var alarmId: String
    var label: String
    var snoozeCost: Double
    var snoozeCount: Int
    var charityName: String
    
    init(alarmId: String, label: String, snoozeCost: Double, snoozeCount: Int = 0, charityName: String = "Darüşşafaka") {
        self.alarmId = alarmId
        self.label = label
        self.snoozeCost = snoozeCost
        self.snoozeCount = snoozeCount
        self.charityName = charityName
    }
}

// MARK: - AlarmKit Service (iOS 26+)

/// Service that wraps Apple's AlarmKit framework for scheduling and managing alarms
/// Provides integration with the system alarm UI and Live Activities
@available(iOS 26.0, *)
@MainActor
final class AlarmKitService: ObservableObject {
    
    static let shared = AlarmKitService()
    
    /// The AlarmKit manager instance
    private let alarmManager = AlarmKit.AlarmManager.shared
    
    /// Published alarms from AlarmKit
    @Published private(set) var activeAlarms: [AlarmKit.Alarm] = []
    
    /// Authorization state
    @Published private(set) var isAuthorized: Bool = false
    
    /// Snooze duration in seconds (9 minutes like iOS default)
    private let snoozeDuration: TimeInterval = 9 * 60
    
    /// Pre-alert countdown duration (optional countdown before alarm alerts)
    private let preAlertCountdown: TimeInterval? = nil
    
    private init() {
        Task {
            await observeAlarmUpdates()
            await checkAuthorization()
        }
    }
    
    // MARK: - Authorization
    
    /// Request authorization to use AlarmKit
    /// - Returns: Whether authorization was granted
    @discardableResult
    func requestAuthorization() async -> Bool {
        print("🔐 AlarmKitService.requestAuthorization() called")
        do {
            print("🔐 Calling alarmManager.requestAuthorization()...")
            let state = try await alarmManager.requestAuthorization()
            print("🔐 AlarmManager returned state: \(state)")
            isAuthorized = state == .authorized
            print("🔐 isAuthorized set to: \(isAuthorized)")
            return isAuthorized
        } catch let error as NSError {
            // Error code 1 typically means AlarmKit is not available
            // This can happen due to: missing entitlements, simulator, or unsupported device
            if error.code == 1 {
                print("⚠️ AlarmKit not available (Code 1) - Missing entitlements or unsupported. Using notification fallback.")
            } else {
                print("❌ AlarmKit authorization error: \(error)")
            }
            isAuthorized = false
            return false
        } catch {
            print("❌ AlarmKit authorization error: \(error)")
            isAuthorized = false
            return false
        }
    }
    
    /// Check current authorization status
    private func checkAuthorization() async {
        let state = alarmManager.authorizationState
        isAuthorized = state == .authorized
    }
    
    // MARK: - Alarm Scheduling
    
    /// Schedule an alarm using AlarmKit
    /// - Parameters:
    ///   - alarm: The app's Alarm model
    func scheduleAlarm(_ alarm: Alarm) async throws {
        let id = alarm.id
        
        // Create schedule
        let schedule = createSchedule(for: alarm)
        
        // Create countdown duration with snooze support
        let countdownDuration = AlarmKit.Alarm.CountdownDuration(
            preAlert: preAlertCountdown,
            postAlert: snoozeDuration
        )
        
        // Create presentation attributes
        let attributes = createAttributes(for: alarm)
        
        // Create the configuration
        let configuration = AlarmKit.AlarmManager.AlarmConfiguration(
            countdownDuration: countdownDuration,
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopAlarmIntent(alarmID: id.uuidString),
            secondaryIntent: SnoozeAlarmIntent(alarmID: id.uuidString, cost: alarm.snoozeCost),
            sound: .default
        )
        
        // Schedule with AlarmKit
        let _ = try await alarmManager.schedule(id: id, configuration: configuration)
        
        print("✅ AlarmKit: Scheduled alarm \(id) for \(alarm.timeString)")
    }
    
    /// Cancel an alarm
    func cancelAlarm(_ alarm: Alarm) {
        do {
            try alarmManager.cancel(id: alarm.id)
            print("🗑️ AlarmKit: Cancelled alarm \(alarm.id)")
        } catch {
            print("❌ AlarmKit: Failed to cancel alarm: \(error)")
        }
    }
    
    /// Cancel alarm by ID
    func cancelAlarm(id: UUID) {
        do {
            try alarmManager.cancel(id: id)
            print("🗑️ AlarmKit: Cancelled alarm \(id)")
        } catch {
            print("❌ AlarmKit: Failed to cancel alarm: \(error)")
        }
    }
    
    /// Stop an alerting alarm
    func stopAlarm(_ alarm: Alarm) {
        do {
            try alarmManager.stop(id: alarm.id)
            print("⏹️ AlarmKit: Stopped alarm \(alarm.id)")
        } catch {
            print("❌ AlarmKit: Failed to stop alarm: \(error)")
        }
    }
    
    /// Stop alarm by ID
    func stopAlarm(id: UUID) {
        do {
            try alarmManager.stop(id: id)
            print("⏹️ AlarmKit: Stopped alarm \(id)")
        } catch {
            print("❌ AlarmKit: Failed to stop alarm: \(error)")
        }
    }
    
    /// Trigger snooze countdown for an alerting alarm
    func snoozeAlarm(_ alarm: Alarm) {
        do {
            try alarmManager.countdown(id: alarm.id)
            print("😴 AlarmKit: Snoozed alarm \(alarm.id) for \(snoozeDuration/60) minutes")
        } catch {
            print("❌ AlarmKit: Failed to snooze alarm: \(error)")
        }
    }
    
    /// Snooze alarm by ID
    func snoozeAlarm(id: UUID) {
        do {
            try alarmManager.countdown(id: id)
            print("😴 AlarmKit: Snoozed alarm \(id)")
        } catch {
            print("❌ AlarmKit: Failed to snooze alarm: \(error)")
        }
    }
    
    /// Pause a countdown alarm
    func pauseAlarm(id: UUID) {
        do {
            try alarmManager.pause(id: id)
            print("⏸️ AlarmKit: Paused alarm \(id)")
        } catch {
            print("❌ AlarmKit: Failed to pause alarm: \(error)")
        }
    }
    
    /// Resume a paused alarm
    func resumeAlarm(id: UUID) {
        do {
            try alarmManager.resume(id: id)
            print("▶️ AlarmKit: Resumed alarm \(id)")
        } catch {
            print("❌ AlarmKit: Failed to resume alarm: \(error)")
        }
    }
    
    // MARK: - Alarm Updates
    
    /// Observe alarm state changes from AlarmKit
    private func observeAlarmUpdates() async {
        for await updatedAlarms in alarmManager.alarmUpdates {
            await MainActor.run {
                self.activeAlarms = updatedAlarms
            }
            
            for alarm in updatedAlarms {
                print("📱 AlarmKit: Alarm \(alarm.id) state: \(AlarmStateDescription.description(for: alarm.state))")
            }
        }
    }
    
    /// Get all current alarms from AlarmKit
    func fetchAlarms() throws -> [AlarmKit.Alarm] {
        return try alarmManager.alarms
    }
    
    /// Get alarm by ID
    func getAlarm(id: UUID) throws -> AlarmKit.Alarm? {
        return try alarmManager.alarms.first { $0.id == id }
    }
    
    // MARK: - Schedule Creation
    
    /// Create an AlarmKit schedule from the app's Alarm model
    private func createSchedule(for alarm: Alarm) -> AlarmKit.Alarm.Schedule? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: alarm.time)
        let minute = calendar.component(.minute, from: alarm.time)
        
        let time = AlarmKit.Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        
        if alarm.repeatDays.isEmpty {
            // One-time alarm
            return .relative(.init(time: time, repeats: .never))
        } else {
            // Repeating alarm - convert Weekday to Locale.Weekday
            let weekdays = alarm.repeatDays.map { convertToLocaleWeekday($0) }
            return .relative(.init(time: time, repeats: .weekly(weekdays)))
        }
    }
    
    /// Convert app's Weekday to Locale.Weekday
    private func convertToLocaleWeekday(_ weekday: Weekday) -> Locale.Weekday {
        switch weekday {
        case .sunday: return .sunday
        case .monday: return .monday
        case .tuesday: return .tuesday
        case .wednesday: return .wednesday
        case .thursday: return .thursday
        case .friday: return .friday
        case .saturday: return .saturday
        }
    }
    
    // MARK: - Presentation Attributes
    
    /// Create AlarmKit presentation attributes
    private func createAttributes(for alarm: Alarm) -> AlarmAttributes<SnoozeAlarmMetadata> {
        let metadata = SnoozeAlarmMetadata(
            alarmId: alarm.id.uuidString,
            label: alarm.label,
            snoozeCost: alarm.snoozeCost,
            snoozeCount: alarm.snoozeCount
        )
        
        let presentation = createPresentation(for: alarm)
        
        return AlarmAttributes(
            presentation: presentation,
            metadata: metadata,
            tintColor: Color.orange // App's brand color
        )
    }
    
    /// Create alarm UI presentation
    private func createPresentation(for alarm: Alarm) -> AlarmPresentation {
        let titleResource = LocalizedStringResource(stringLiteral: alarm.label.isEmpty ? "Snooze If You Can" : alarm.label)
        
        // Alert presentation (when alarm fires)
        let alertContent = AlarmPresentation.Alert(
            title: titleResource,
            stopButton: AlarmButton(
                text: LocalizedStringResource(stringLiteral: "Wake Up"),
                textColor: .green,
                systemImageName: "sun.max.fill"
            ),
            secondaryButton: AlarmButton(
                text: LocalizedStringResource(stringLiteral: "💰 Snooze"),
                textColor: .orange,
                systemImageName: "bed.double.fill"
            ),
            secondaryButtonBehavior: .countdown // Use countdown behavior for snooze
        )
        
        // Countdown presentation (during snooze)
        let countdownContent = AlarmPresentation.Countdown(
            title: LocalizedStringResource(stringLiteral: "Snoozing...")
        )
        
        // Paused presentation
        let pausedContent = AlarmPresentation.Paused(
            title: LocalizedStringResource(stringLiteral: "Paused"),
            resumeButton: AlarmButton(
                text: LocalizedStringResource(stringLiteral: "Resume"),
                textColor: .blue,
                systemImageName: "play.fill"
            )
        )
        
        return AlarmPresentation(
            alert: alertContent,
            countdown: countdownContent,
            paused: pausedContent
        )
    }
}

// MARK: - Alarm Service Helper

/// Helper to access AlarmKit functionality with proper availability checks
enum AlarmServiceHelper {
    
    @MainActor
    static func requestAuthorization() async -> Bool {
        if #available(iOS 26.0, *) {
            // Try AlarmKit first
            let alarmKitGranted = await AlarmKitService.shared.requestAuthorization()
            if alarmKitGranted {
                print("✅ AlarmKit authorization successful")
                return true
            }
            
            // AlarmKit failed (possibly simulator) - fall back to notifications
            print("⚠️ AlarmKit failed, falling back to notifications")
        }
        
        // Fallback to notification permission
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, _ in
                print("📱 Notification authorization: \(granted)")
                continuation.resume(returning: granted)
            }
        }
    }
    
    @MainActor
    static func scheduleAlarm(_ alarm: Alarm) async throws {
        if #available(iOS 26.0, *), AlarmKitService.shared.isAuthorized {
            try await AlarmKitService.shared.scheduleAlarm(alarm)
        } else {
            NotificationManager.shared.scheduleAlarm(alarm)
        }
    }
    
    @MainActor
    static func cancelAlarm(_ alarm: Alarm) {
        if #available(iOS 26.0, *), AlarmKitService.shared.isAuthorized {
            AlarmKitService.shared.cancelAlarm(alarm)
        }
        // Always cancel notifications as fallback
        NotificationManager.shared.cancelAlarm(alarm)
    }
    
    @MainActor
    static func stopAlarm(_ alarm: Alarm) {
        if #available(iOS 26.0, *), AlarmKitService.shared.isAuthorized {
            AlarmKitService.shared.stopAlarm(alarm)
        }
        NotificationManager.shared.cancelAlarm(alarm)
    }
    
    @MainActor
    static func snoozeAlarm(_ alarm: Alarm) {
        if #available(iOS 26.0, *), AlarmKitService.shared.isAuthorized {
            AlarmKitService.shared.snoozeAlarm(alarm)
        } else {
            NotificationManager.shared.scheduleSnooze(alarm, minutes: 9)
        }
    }
}

// MARK: - AlarmKit State Helpers

@available(iOS 26.0, *)
enum AlarmStateDescription {
    static func description(for state: AlarmKit.Alarm.State) -> String {
        switch state {
        case .scheduled:
            return "Scheduled"
        case .alerting:
            return "Alerting"
        case .countdown:
            return "Countdown"
        case .paused:
            return "Paused"
        @unknown default:
            return "Unknown"
        }
    }
}
