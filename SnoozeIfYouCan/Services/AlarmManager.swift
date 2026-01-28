import Foundation
import Combine
import AlarmKit

/// Central manager for alarm CRUD operations and business logic
///
/// `AlarmManager` is the main coordinator for all alarm-related functionality in the app.
/// It manages the lifecycle of alarms, handles snooze logic with escalating costs,
/// tracks donation statistics, and coordinates with both AlarmKit (iOS 26+) and
/// UserNotifications (fallback) for alarm scheduling.
///
/// ## Features
/// - Alarm creation, updating, deletion, and toggling
/// - Snooze handling with escalating cost tiers ($0.99 → $9.99)
/// - Maximum 5 snoozes per alarm enforcement
/// - Donation statistics tracking (streaks, totals, weekly/monthly)
/// - AlarmKit integration with automatic fallback to UserNotifications
/// - Local persistence via UserDefaults
///
/// ## Usage
/// ```swift
/// @StateObject private var alarmManager = AlarmManager()
///
/// // Create an alarm
/// let alarm = Alarm(time: Date(), label: "Morning Wake Up")
/// alarmManager.addAlarm(alarm)
///
/// // Handle snooze
/// let cost = alarmManager.snoozeAlarm(alarm)
/// ```
///
/// - Note: This manager automatically chooses between AlarmKit and UserNotifications
///   based on availability and authorization status.
/// - Important: Alarms scheduled via UserNotifications are not guaranteed to fire
///   with the same reliability as native Clock app alarms.
@MainActor
final class AlarmManager: ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var snoozeRecords: [SnoozeRecord] = []
    @Published var stats: DonationStats = DonationStats()
    
    /// Whether to use AlarmKit (iOS 26+) or fallback to UserNotifications
    private var useAlarmKit: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }
    
    private let alarmsKey = "saved_alarms"
    private let recordsKey = "snooze_records"
    private let statsKey = "donation_stats"
    private let costTiers: [Double] = [0.99, 1.99, 2.99, 4.99, 9.99]
    private let maxSnoozes = 5
    
    init() {
        loadAlarms()
        loadRecords()
        loadStats()
        
        // Observe AlarmKit updates if available
        if #available(iOS 26.0, *) {
            Task {
                await observeAlarmKitUpdates()
            }
        }
    }
    
    // MARK: - AlarmKit Integration
    
    /// Observe alarm state changes from AlarmKit
    @available(iOS 26.0, *)
    private func observeAlarmKitUpdates() async {
        for await alarmKitAlarms in AlarmKit.AlarmManager.shared.alarmUpdates {
            await handleAlarmKitUpdates(alarmKitAlarms)
        }
    }
    
    /// Handle AlarmKit alarm state changes
    @available(iOS 26.0, *)
    private func handleAlarmKitUpdates(_ alarmKitAlarms: [AlarmKit.Alarm]) async {
        for kitAlarm in alarmKitAlarms {
            // Find matching app alarm
            guard alarms.contains(where: { $0.id == kitAlarm.id }) else {
                continue
            }
            
            // Update alarm state based on AlarmKit state
            switch kitAlarm.state {
            case .alerting:
                // Post notification for app to show full-screen alarm UI if needed
                NotificationCenter.default.post(
                    name: .alarmDidFire,
                    object: nil,
                    userInfo: ["alarmId": kitAlarm.id.uuidString]
                )
                
            case .countdown:
                // Alarm was snoozed - update snooze count
                print("📱 Alarm \(kitAlarm.id) is in snooze countdown")
                
            case .scheduled:
                // Alarm is scheduled normally
                print("📱 Alarm \(kitAlarm.id) is scheduled")
                
            case .paused:
                print("📱 Alarm \(kitAlarm.id) is paused")
                
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Alarm CRUD
    
    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        saveAlarms()
        
        if alarm.isEnabled {
            scheduleAlarmNotification(alarm)
        }
    }
    
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            saveAlarms()
            
            cancelAlarmNotification(alarm)
            if alarm.isEnabled {
                scheduleAlarmNotification(alarm)
            }
        }
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
        cancelAlarmNotification(alarm)
    }
    
    func toggleAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            saveAlarms()
            
            if alarms[index].isEnabled {
                scheduleAlarmNotification(alarms[index])
            } else {
                cancelAlarmNotification(alarms[index])
            }
        }
    }
    
    // MARK: - Notification Scheduling (AlarmKit or UserNotifications)
    
    private func scheduleAlarmNotification(_ alarm: Alarm) {
        Task {
            do {
                try await AlarmServiceHelper.scheduleAlarm(alarm)
            } catch {
                print("❌ Alarm scheduling failed: \(error)")
                // Fallback to UserNotifications
                NotificationManager.shared.scheduleAlarm(alarm)
            }
        }
    }
    
    private func cancelAlarmNotification(_ alarm: Alarm) {
        AlarmServiceHelper.cancelAlarm(alarm)
    }
    
    // MARK: - Snooze Handling
    
    func snoozeAlarm(_ alarm: Alarm) -> Double {
        guard !hasReachedMaxSnoozes(alarm) else { return 0 }
        let cost = getNextSnoozeCost(for: alarm)
        
        // Update alarm snooze count
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].snoozeCount += 1
            alarms[index].lastSnoozeDate = Date()
            saveAlarms()
        }
        
        // Record the snooze
        let record = SnoozeRecord(
            alarmId: alarm.id,
            date: Date(),
            amount: cost
        )
        snoozeRecords.append(record)
        saveRecords()
        
        // Update stats
        stats.totalSnoozes += 1
        stats.totalDonated += cost
        stats.currentWeekAmount += cost
        stats.currentMonthAmount += cost
        stats.currentStreak = 0 // Reset streak on snooze
        saveStats()
        
        // Schedule snooze using AlarmKit or UserNotifications
        AlarmServiceHelper.snoozeAlarm(alarm)
        
        return cost
    }
    
    func dismissAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].snoozeCount = 0
            alarms[index].lastSnoozeDate = nil
            saveAlarms()
            
            // Update streak for successful wake-up
            stats.currentStreak += 1
            if stats.currentStreak > stats.longestStreak {
                stats.longestStreak = stats.currentStreak
            }
            saveStats()
        }
        
        // Stop alarm
        AlarmServiceHelper.stopAlarm(alarm)
    }
    
    func getNextSnoozeCost(for alarm: Alarm) -> Double {
        let tierIndex = min(alarm.snoozeCount, costTiers.count - 1)
        return costTiers[tierIndex]
    }
    
    func hasReachedMaxSnoozes(_ alarm: Alarm) -> Bool {
        alarm.snoozeCount >= maxSnoozes
    }
    
    // MARK: - Persistence
    
    private func saveAlarms() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: alarmsKey)
        }
    }
    
    private func loadAlarms() {
        if let data = UserDefaults.standard.data(forKey: alarmsKey),
           let decoded = try? JSONDecoder().decode([Alarm].self, from: data) {
            alarms = decoded
        }
    }
    
    private func saveRecords() {
        if let data = try? JSONEncoder().encode(snoozeRecords) {
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
    }
    
    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([SnoozeRecord].self, from: data) {
            snoozeRecords = decoded
        }
    }
    
    private func saveStats() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: statsKey)
        }
    }
    
    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(DonationStats.self, from: data) {
            stats = decoded
        }
    }
}
