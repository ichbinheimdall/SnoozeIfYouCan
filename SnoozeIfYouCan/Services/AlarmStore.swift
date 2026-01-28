import Foundation

// MARK: - Alarm Manager (Modern @Observable)
// Uses iOS 17+ Observation framework for reactive state management

@available(iOS 17.0, *)
@Observable
@MainActor
final class AlarmStore {
    // MARK: - State
    var alarms: [Alarm] = []
    var snoozeRecords: [SnoozeRecord] = []
    var stats: DonationStats = DonationStats()
    
    // MARK: - Non-observed
    @ObservationIgnored
    private let alarmsKey = "saved_alarms_v2"
    @ObservationIgnored
    private let recordsKey = "snooze_records_v2"
    @ObservationIgnored
    private let statsKey = "donation_stats_v2"
    @ObservationIgnored
    private let defaults = UserDefaults.standard
    
    // MARK: - Snooze Cost Tiers (Escalating)
    /// Fixed escalating costs: 1st=$0.99, 2nd=$1.99, 3rd=$2.99, 4th=$4.99, 5th=$9.99
    @ObservationIgnored
    static let snoozeCostTiers: [Double] = [0.99, 1.99, 2.99, 4.99, 9.99]
    
    /// Maximum allowed snoozes before forced wake-up
    @ObservationIgnored
    static let maxSnoozes = 5
    
    init() {
        loadAll()
        resetSnoozeCountsIfNeeded()
    }
    
    // MARK: - Snooze Cost Calculation
    
    /// Get the cost for the next snooze (1-indexed)
    func getNextSnoozeCost(for alarm: Alarm) -> Double {
        let snoozeIndex = min(alarm.snoozeCount, Self.snoozeCostTiers.count - 1)
        return Self.snoozeCostTiers[snoozeIndex]
    }
    
    /// Check if alarm has reached maximum snoozes
    func hasReachedMaxSnoozes(_ alarm: Alarm) -> Bool {
        alarm.snoozeCount >= Self.maxSnoozes
    }
    
    /// Get remaining snoozes
    func remainingSnoozes(for alarm: Alarm) -> Int {
        max(0, Self.maxSnoozes - alarm.snoozeCount)
    }
    
    // MARK: - Alarm CRUD
    
    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        save()
        
        if alarm.isEnabled {
            NotificationManager.shared.scheduleAlarm(alarm)
        }
    }
    
    func updateAlarm(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        
        alarms[index] = alarm
        save()
        
        NotificationManager.shared.cancelAlarm(alarm)
        if alarm.isEnabled {
            NotificationManager.shared.scheduleAlarm(alarm)
        }
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        save()
        NotificationManager.shared.cancelAlarm(alarm)
    }
    
    func toggleAlarm(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        
        alarms[index].isEnabled.toggle()
        save()
        
        if alarms[index].isEnabled {
            NotificationManager.shared.scheduleAlarm(alarms[index])
        } else {
            NotificationManager.shared.cancelAlarm(alarms[index])
        }
    }
    
    // MARK: - Snooze Handling
    
    /// Execute snooze with payment - returns the cost charged
    @discardableResult
    func snoozeAlarm(_ alarm: Alarm) -> Double {
        guard !hasReachedMaxSnoozes(alarm) else { return 0 }
        
        let cost = getNextSnoozeCost(for: alarm)
        
        // Update alarm snooze count
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].snoozeCount += 1
            alarms[index].lastSnoozeDate = Date()
        }
        
        // Record the snooze
        let record = SnoozeRecord(
            alarmId: alarm.id,
            date: Date(),
            amount: cost
        )
        snoozeRecords.append(record)
        
        // Update stats
        stats.totalSnoozes += 1
        stats.totalDonated += cost
        stats.currentWeekAmount += cost
        stats.currentMonthAmount += cost
        
        save()
        
        // Schedule next snooze notification (5 minutes)
        NotificationManager.shared.scheduleSnooze(alarm, minutes: 5)
        
        return cost
    }
    
    /// Dismiss alarm without snoozing - updates streak
    func dismissAlarm(_ alarm: Alarm) {
        // Reset snooze count
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            let wasSnoozeFreeze = alarms[index].snoozeCount == 0
            alarms[index].snoozeCount = 0
            alarms[index].lastSnoozeDate = nil
            
            // Update streak only if snooze-free
            if wasSnoozeFreeze {
                updateStreak()
            } else {
                resetStreak()
            }
        }
        
        stats.snoozeFreeWakeUps += 1
        save()
        
        NotificationManager.shared.cancelAlarm(alarm)
    }
    
    // MARK: - Streak Management
    
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = stats.lastStreakDate {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            
            if Calendar.current.isDate(lastDate, inSameDayAs: yesterday) {
                // Consecutive day
                stats.currentStreak += 1
            } else if !Calendar.current.isDate(lastDate, inSameDayAs: today) {
                // Gap in streak
                stats.currentStreak = 1
            }
            // Same day = no change
        } else {
            stats.currentStreak = 1
        }
        
        stats.longestStreak = max(stats.longestStreak, stats.currentStreak)
        stats.lastStreakDate = today
    }
    
    private func resetStreak() {
        stats.currentStreak = 0
    }
    
    // MARK: - Daily Reset
    
    /// Reset snooze counts at midnight
    private func resetSnoozeCountsIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        
        for i in alarms.indices {
            if let lastSnooze = alarms[i].lastSnoozeDate,
               !Calendar.current.isDate(lastSnooze, inSameDayAs: today) {
                alarms[i].snoozeCount = 0
                alarms[i].lastSnoozeDate = nil
            }
        }
        
        // Reset weekly/monthly if needed
        resetPeriodicStats()
    }
    
    private func resetPeriodicStats() {
        let now = Date()
        let calendar = Calendar.current
        
        // Weekly reset
        if let weekStart = stats.weekStartDate {
            if !calendar.isDate(now, equalTo: weekStart, toGranularity: .weekOfYear) {
                stats.currentWeekAmount = 0
                stats.weekStartDate = calendar.startOfWeek(for: now)
            }
        } else {
            stats.weekStartDate = calendar.startOfWeek(for: now)
        }
        
        // Monthly reset
        if let monthStart = stats.monthStartDate {
            if !calendar.isDate(now, equalTo: monthStart, toGranularity: .month) {
                stats.currentMonthAmount = 0
                stats.monthStartDate = calendar.startOfMonth(for: now)
            }
        } else {
            stats.monthStartDate = calendar.startOfMonth(for: now)
        }
    }
    
    // MARK: - Persistence
    
    private func save() {
        saveAlarms()
        saveRecords()
        saveStats()
    }
    
    private func loadAll() {
        loadAlarms()
        loadRecords()
        loadStats()
    }
    
    private func saveAlarms() {
        guard let data = try? JSONEncoder().encode(alarms) else { return }
        defaults.set(data, forKey: alarmsKey)
    }
    
    private func loadAlarms() {
        guard let data = defaults.data(forKey: alarmsKey),
              let decoded = try? JSONDecoder().decode([Alarm].self, from: data) else { return }
        alarms = decoded
    }
    
    private func saveRecords() {
        guard let data = try? JSONEncoder().encode(snoozeRecords) else { return }
        defaults.set(data, forKey: recordsKey)
    }
    
    private func loadRecords() {
        guard let data = defaults.data(forKey: recordsKey),
              let decoded = try? JSONDecoder().decode([SnoozeRecord].self, from: data) else { return }
        snoozeRecords = decoded
    }
    
    private func saveStats() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults.set(data, forKey: statsKey)
    }
    
    private func loadStats() {
        guard let data = defaults.data(forKey: statsKey),
              let decoded = try? JSONDecoder().decode(DonationStats.self, from: data) else { return }
        stats = decoded
    }
}

// MARK: - Calendar Extensions

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
    
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

// Note: Alarm and DonationStats models are defined in their respective files
// - Alarm is defined in Models/Alarm.swift
// - DonationStats is defined in Models/SnoozeRecord.swift
