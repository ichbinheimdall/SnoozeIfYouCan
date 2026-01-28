import SwiftData
import Foundation
import Combine

// MARK: - SwiftData Models
// Modern persistence with automatic CloudKit sync capability

/// Alarm model for SwiftData persistence
@available(iOS 17.0, *)
@Model
final class SDAlarm {
    // Unique identifier
    var id: UUID
    
    // Core properties
    var time: Date
    var label: String
    var isEnabled: Bool
    var snoozeCost: Double
    var snoozeCount: Int
    
    // Repeat configuration stored as raw values
    var repeatDaysRaw: [Int]
    
    // Sound configuration
    var soundName: String
    var volume: Double
    var increasingVolume: Bool
    
    // Metadata
    var createdAt: Date
    var lastTriggered: Date?
    var totalSnoozes: Int
    var totalDonated: Double
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \SDSnoozeRecord.alarm)
    var snoozeRecords: [SDSnoozeRecord]?
    
    init(
        id: UUID = UUID(),
        time: Date,
        label: String = "",
        isEnabled: Bool = true,
        snoozeCost: Double = 1.0,
        snoozeCount: Int = 0,
        repeatDays: Set<Weekday> = [],
        soundName: String = "radar",
        volume: Double = 1.0,
        increasingVolume: Bool = false
    ) {
        self.id = id
        self.time = time
        self.label = label
        self.isEnabled = isEnabled
        self.snoozeCost = snoozeCost
        self.snoozeCount = snoozeCount
        self.repeatDaysRaw = repeatDays.map { $0.rawValue }
        self.soundName = soundName
        self.volume = volume
        self.increasingVolume = increasingVolume
        self.createdAt = Date()
        self.totalSnoozes = 0
        self.totalDonated = 0
    }
    
    // Computed property for repeat days
    var repeatDays: Set<Weekday> {
        get {
            Set(repeatDaysRaw.compactMap { Weekday(rawValue: $0) })
        }
        set {
            repeatDaysRaw = newValue.map { $0.rawValue }
        }
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    var repeatDescription: String {
        if repeatDays.isEmpty {
            return "Once"
        } else if repeatDays.count == 7 {
            return "Every day"
        } else if repeatDays == [.saturday, .sunday] {
            return "Weekends"
        } else if repeatDays == [.monday, .tuesday, .wednesday, .thursday, .friday] {
            return "Weekdays"
        } else {
            return repeatDays.sorted(by: { $0.rawValue < $1.rawValue })
                .map { $0.shortName }
                .joined(separator: ", ")
        }
    }
    
    // Convert to legacy Alarm model for compatibility
    func toLegacyAlarm() -> Alarm {
        Alarm(
            id: id,
            time: time,
            label: label,
            isEnabled: isEnabled,
            repeatDays: repeatDays,
            snoozeCost: snoozeCost,
            snoozeCount: snoozeCount
        )
    }
    
    // Create from legacy model
    static func from(_ alarm: Alarm) -> SDAlarm {
        SDAlarm(
            id: alarm.id,
            time: alarm.time,
            label: alarm.label,
            isEnabled: alarm.isEnabled,
            snoozeCost: alarm.snoozeCost,
            snoozeCount: alarm.snoozeCount,
            repeatDays: alarm.repeatDays
        )
    }
}

/// Snooze record model for SwiftData
@available(iOS 17.0, *)
@Model
final class SDSnoozeRecord {
    var id: UUID
    var date: Date
    var amount: Double
    var alarmLabel: String
    
    // Parent alarm (optional for historical records)
    var alarm: SDAlarm?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Double,
        alarmLabel: String = "",
        alarm: SDAlarm? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.alarmLabel = alarmLabel
        self.alarm = alarm
    }
}

/// User statistics model for SwiftData
@available(iOS 17.0, *)
@Model
final class SDUserStats {
    var id: UUID
    var totalDonated: Double
    var totalSnoozes: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastWakeDate: Date?
    
    // Weekly/Monthly tracking
    var currentWeekAmount: Double
    var currentMonthAmount: Double
    var weekStartDate: Date
    var monthStartDate: Date
    
    // Achievement tracking
    var unlockedAchievementIds: [String]
    
    init() {
        self.id = UUID()
        self.totalDonated = 0
        self.totalSnoozes = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.currentWeekAmount = 0
        self.currentMonthAmount = 0
        self.weekStartDate = Date().startOfWeek
        self.monthStartDate = Date().startOfMonth
        self.unlockedAchievementIds = []
    }
    
    func recordSnooze(amount: Double) {
        totalSnoozes += 1
        totalDonated += amount
        currentWeekAmount += amount
        currentMonthAmount += amount
        
        // Reset streak
        currentStreak = 0
    }
    
    func recordWakeUp() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastWake = lastWakeDate {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            if Calendar.current.isDate(lastWake, inSameDayAs: yesterday) {
                currentStreak += 1
            } else if !Calendar.current.isDate(lastWake, inSameDayAs: today) {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }
        
        longestStreak = max(longestStreak, currentStreak)
        lastWakeDate = today
    }
    
    func refreshPeriods() {
        let now = Date()
        
        // Check if we need to reset weekly
        if now > weekStartDate.addingDays(7) {
            currentWeekAmount = 0
            weekStartDate = now.startOfWeek
        }
        
        // Check if we need to reset monthly
        if !Calendar.current.isDate(now, equalTo: monthStartDate, toGranularity: .month) {
            currentMonthAmount = 0
            monthStartDate = now.startOfMonth
        }
    }
}

// MARK: - Date Extensions for SwiftData

extension Date {
    var startOfWeek: Date {
        Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date ?? self
    }
    
    var startOfMonth: Date {
        Calendar.current.dateComponents([.calendar, .year, .month], from: self).date ?? self
    }
    
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}

// MARK: - SwiftData Container Configuration

@available(iOS 17.0, *)
struct DataContainer {
    static let shared = DataContainer()
    
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            SDAlarm.self,
            SDSnoozeRecord.self,
            SDUserStats.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier("group.com.snoozeifyoucan.app"),
            cloudKitDatabase: .automatic
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }
}

// MARK: - SwiftData Manager

@available(iOS 17.0, *)
@MainActor
class SwiftDataManager: ObservableObject {
    private let modelContext: ModelContext
    
    @Published var alarms: [SDAlarm] = []
    @Published var stats: SDUserStats?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchAlarms()
        fetchOrCreateStats()
    }
    
    // MARK: - Alarms
    
    func fetchAlarms() {
        let descriptor = FetchDescriptor<SDAlarm>(
            sortBy: [SortDescriptor(\.time)]
        )
        
        do {
            alarms = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch alarms: \(error)")
        }
    }
    
    func addAlarm(_ alarm: SDAlarm) {
        modelContext.insert(alarm)
        saveContext()
        fetchAlarms()
    }
    
    func deleteAlarm(_ alarm: SDAlarm) {
        modelContext.delete(alarm)
        saveContext()
        fetchAlarms()
    }
    
    // MARK: - Stats
    
    func fetchOrCreateStats() {
        let descriptor = FetchDescriptor<SDUserStats>()
        
        do {
            let results = try modelContext.fetch(descriptor)
            if let existing = results.first {
                stats = existing
            } else {
                let newStats = SDUserStats()
                modelContext.insert(newStats)
                saveContext()
                stats = newStats
            }
        } catch {
            print("Failed to fetch stats: \(error)")
        }
    }
    
    // MARK: - Snooze
    
    func recordSnooze(for alarm: SDAlarm, amount: Double) {
        let record = SDSnoozeRecord(
            amount: amount,
            alarmLabel: alarm.label,
            alarm: alarm
        )
        modelContext.insert(record)
        
        alarm.snoozeCount += 1
        alarm.totalSnoozes += 1
        alarm.totalDonated += amount
        
        stats?.recordSnooze(amount: amount)
        
        saveContext()
    }
    
    func dismissAlarm(_ alarm: SDAlarm) {
        alarm.snoozeCount = 0
        alarm.lastTriggered = Date()
        
        stats?.recordWakeUp()
        
        saveContext()
    }
    
    // MARK: - Context
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

// MARK: - Migration Helper

@available(iOS 17.0, *)
struct MigrationHelper {
    
    /// Migrate from UserDefaults to SwiftData
    static func migrateFromUserDefaults(to manager: SwiftDataManager) {
        let legacyManager = AlarmManager()
        
        // Only migrate if SwiftData is empty and UserDefaults has data
        guard manager.alarms.isEmpty && !legacyManager.alarms.isEmpty else { return }
        
        // Migrate alarms
        for alarm in legacyManager.alarms {
            let sdAlarm = SDAlarm.from(alarm)
            manager.addAlarm(sdAlarm)
        }
        
        // Migrate stats
        if let stats = manager.stats {
            stats.totalDonated = legacyManager.stats.totalDonated
            stats.totalSnoozes = legacyManager.stats.totalSnoozes
            stats.currentStreak = legacyManager.stats.currentStreak
            stats.longestStreak = legacyManager.stats.longestStreak
        }
        
        print("Migration complete: \(legacyManager.alarms.count) alarms migrated")
    }
}
