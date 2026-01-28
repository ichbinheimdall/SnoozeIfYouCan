import Foundation

/// Core alarm data model
///
/// Represents a single alarm with all its configuration, including time, label,
/// repeat schedule, and snooze tracking information.
///
/// ## Properties
/// - `id`: Unique identifier, also used as AlarmKit alarm ID
/// - `time`: The time when the alarm should fire (date component is ignored, only time matters)
/// - `label`: User-friendly name for the alarm
/// - `isEnabled`: Whether the alarm is currently active
/// - `repeatDays`: Set of weekdays for repeating alarms (empty = one-time alarm)
/// - `snoozeCost`: Base cost in USD for the first snooze
/// - `snoozeCount`: Number of times snoozed today (resets on dismiss)
/// - `lastSnoozeDate`: Timestamp of the most recent snooze
///
/// ## Usage
/// ```swift
/// // Create a one-time alarm
/// let alarm = Alarm(
///     time: Date(),
///     label: "Morning Workout",
///     isEnabled: true
/// )
///
/// // Create a weekday repeating alarm
/// var weekdayAlarm = Alarm(time: Date(), label: "Work Day")
/// weekdayAlarm.repeatDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
/// ```
///
/// - Note: The `snoozeCount` resets to 0 when the alarm is dismissed (not snoozed).
///   This allows for escalating costs each morning without persisting across days.
struct Alarm: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var time: Date
    var label: String
    var isEnabled: Bool = true
    var repeatDays: Set<Weekday> = []
    var snoozeCost: Double = 1.0  // Cost in USD to snooze
    var snoozeCount: Int = 0      // Times snoozed today
    var lastSnoozeDate: Date? = nil
    
    /// AlarmKit alarm ID (same as id for direct mapping)
    var alarmKitId: UUID { id }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    var repeatDescription: String {
        if repeatDays.isEmpty {
            return L10n.Alarm.once
        } else if repeatDays.count == 7 {
            return L10n.Alarm.everyDay
        } else if repeatDays == [.saturday, .sunday] {
            return L10n.Alarm.weekends
        } else if repeatDays == [.monday, .tuesday, .wednesday, .thursday, .friday] {
            return L10n.Alarm.weekdays
        } else {
            return repeatDays.sorted(by: { $0.rawValue < $1.rawValue })
                .map { $0.shortName }
                .joined(separator: ", " )
        }
    }
    
    /// Whether this is a repeating alarm
    var isRepeating: Bool {
        !repeatDays.isEmpty
    }
    
    /// Get next fire date for this alarm
    var nextFireDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        
        if repeatDays.isEmpty {
            // One-time alarm - return time if it's in the future
            let todayAlarm = calendar.date(
                bySettingHour: calendar.component(.hour, from: time),
                minute: calendar.component(.minute, from: time),
                second: 0,
                of: now
            )
            
            if let alarm = todayAlarm, alarm > now {
                return alarm
            }
            // Already passed today, return tomorrow
            return todayAlarm?.addingTimeInterval(24 * 60 * 60)
        } else {
            // Repeating alarm - find next occurrence
            let hour = calendar.component(.hour, from: time)
            let minute = calendar.component(.minute, from: time)
            
            for dayOffset in 0...7 {
                guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else {
                    continue
                }
                
                let weekday = calendar.component(.weekday, from: checkDate)
                guard let appWeekday = Weekday(rawValue: weekday),
                      repeatDays.contains(appWeekday) else {
                    continue
                }
                
                if let alarmDate = calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: checkDate
                ), alarmDate > now {
                    return alarmDate
                }
            }
            return nil
        }
    }
}

enum Weekday: Int, Codable, CaseIterable, Hashable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var shortName: String {
        switch self {
        case .sunday: return L10n.Weekdays.sunShort
        case .monday: return L10n.Weekdays.monShort
        case .tuesday: return L10n.Weekdays.tueShort
        case .wednesday: return L10n.Weekdays.wedShort
        case .thursday: return L10n.Weekdays.thuShort
        case .friday: return L10n.Weekdays.friShort
        case .saturday: return L10n.Weekdays.satShort
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return L10n.Weekdays.sunday
        case .monday: return L10n.Weekdays.monday
        case .tuesday: return L10n.Weekdays.tuesday
        case .wednesday: return L10n.Weekdays.wednesday
        case .thursday: return L10n.Weekdays.thursday
        case .friday: return L10n.Weekdays.friday
        case .saturday: return L10n.Weekdays.saturday
        }
    }
    
    /// Convert to Locale.Weekday for AlarmKit
    @available(iOS 26.0, *)
    var localeWeekday: Locale.Weekday {
        switch self {
        case .sunday: return .sunday
        case .monday: return .monday
        case .tuesday: return .tuesday
        case .wednesday: return .wednesday
        case .thursday: return .thursday
        case .friday: return .friday
        case .saturday: return .saturday
        }
    }
}
