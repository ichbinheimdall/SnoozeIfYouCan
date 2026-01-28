import Foundation
import UserNotifications

/// Fallback notification manager for alarm delivery when AlarmKit is unavailable
///
/// `NotificationManager` provides UserNotifications-based alarm scheduling as a fallback
/// when Apple's AlarmKit is not available or authorized. It uses critical alerts and
/// time-sensitive notifications to maximize delivery reliability.
///
/// ## Features
/// - Critical alert support (requires special entitlement)
/// - Time-sensitive notifications to bypass Focus modes
/// - Custom notification categories with snooze/dismiss actions
/// - Notification sound configuration
/// - Schedule validation and error handling
///
/// ## Limitations
/// ⚠️ **Important**: UserNotifications are NOT as reliable as native alarms:
/// - Can be dismissed by user without waking them
/// - System can delay or drop notifications under resource pressure
/// - No guarantee of delivery when app is terminated
/// - Background refresh must be enabled
/// - Cannot wake device from deep sleep
///
/// **This is a fallback only** - Use AlarmKit when available for production alarms.
///
/// ## Usage
/// ```swift
/// // Request permission
/// NotificationManager.shared.requestPermission(allowCritical: true)
///
/// // Schedule an alarm
/// NotificationManager.shared.scheduleAlarm(alarm)
/// ```
///
/// - Warning: Critical alerts should only be used for apps with genuine critical needs
///   (health, safety, security). Alarm apps may face App Store review challenges.
class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission(allowCritical: Bool = false) {
        var options: UNAuthorizationOptions = [.alert, .sound, .badge, .providesAppNotificationSettings]
        
        if allowCritical {
            options.insert(.criticalAlert)
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if granted {
                print("✅ Notification permission granted")
                // Setup categories after permission granted
                DispatchQueue.main.async {
                    self.setupNotificationCategories()
                }
            } else if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleAlarm(_ alarm: Alarm) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ " + L10n.Common.appName
        content.subtitle = alarm.label.isEmpty ? "" : alarm.label
        content.body = alarm.label.isEmpty ? String(localized: "Time to rise and shine! 🌅") : String(localized: "Time to wake up! Snoozing costs $\(String(format: "%.2f", alarm.snoozeCost)) 💰")
        content.sound = criticalSound()
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.userInfo = ["alarmId": alarm.id.uuidString, "shouldLaunchApp": true]
        
        // Make it time-sensitive to break through Focus modes
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0 // Highest relevance
        
        // This makes the notification launch the app when tapped
        content.targetContentIdentifier = "alarm_\(alarm.id.uuidString)"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: alarm.time)
        
        if alarm.repeatDays.isEmpty {
            // One-time alarm
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: alarm.id.uuidString,
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule alarm: \(error.localizedDescription)")
                } else {
                    print("✅ Alarm scheduled for \(alarm.timeString)")
                }
            }
        } else {
            // Repeating alarm - schedule for each day
            for day in alarm.repeatDays {
                var dateComponents = components
                dateComponents.weekday = day.rawValue
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(alarm.id.uuidString)_\(day.rawValue)",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ Failed to schedule alarm for \(day.fullName): \(error.localizedDescription)")
                    }
                }
            }
            print("✅ Repeating alarm scheduled for \(alarm.repeatDescription)")
        }
    }
    
    func scheduleSnooze(_ alarm: Alarm, minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ " + L10n.Common.appName
        content.subtitle = "Snooze finished!"
        content.body = String(localized: "Time to wake up! You donated for this snooze 💤")
        content.sound = criticalSound()
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.userInfo = ["alarmId": alarm.id.uuidString, "isSnooze": true, "shouldLaunchApp": true]
        
        // Make it time-sensitive
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        
        // This makes the notification launch the app when tapped
        content.targetContentIdentifier = "snooze_\(alarm.id.uuidString)"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(alarm.id.uuidString)_snooze",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule snooze: \(error.localizedDescription)")
            } else {
                print("✅ Snooze scheduled for \(minutes) minutes")
            }
        }
    }
    
    func cancelAlarm(_ alarm: Alarm) {
        var identifiers = [alarm.id.uuidString, "\(alarm.id.uuidString)_snooze"]
        
        // Also cancel all weekday-specific notifications
        for day in Weekday.allCases {
            identifiers.append("\(alarm.id.uuidString)_\(day.rawValue)")
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ Alarm cancelled")
    }
    
    func cancelAllAlarms() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ All alarms cancelled")
    }
    
    func setupNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "💰 Snooze (Pay to Sleep)",
            options: [.foreground] // This brings the app to foreground
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "✅ I'm Awake!",
            options: [.foreground] // Changed to foreground to launch app
        )
        
        let category = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

// MARK: - Critical Sound Helper

private extension NotificationManager {
    func criticalSound() -> UNNotificationSound? {
        // Use critical alert sound with volume 1.0 (max)
        // Critical alerts can play for up to 60 seconds and bypass silent mode
        if #available(iOS 12.0, *) {
            #if targetEnvironment(simulator)
            // Simulator doesn't properly support critical alerts audio sessions
            // Use default sound to prevent ToneLibrary crashes
            return UNNotificationSound.default
            #else
            // For critical alerts: plays at max volume and ignores mute switch
            return UNNotificationSound.defaultCriticalSound(withAudioVolume: 1.0)
            #endif
        } else {
            return UNNotificationSound.default
        }
    }
}
