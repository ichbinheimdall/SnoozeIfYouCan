import Foundation

// MARK: - Localization Keys
// Supports Turkish (TR) and English (EN)
// Usage: Text(L10n.Alarm.snoozeButton)

enum L10n {
    
    // MARK: - Common
    enum Common {
        static let appName = String(localized: "Snooze If You Can", comment: "App name")
        static let cancel = String(localized: "Cancel", comment: "Cancel button")
        static let done = String(localized: "Done", comment: "Done button")
        static let save = String(localized: "Save", comment: "Save button")
        static let delete = String(localized: "Delete", comment: "Delete button")
        static let edit = String(localized: "Edit", comment: "Edit button")
        static let settings = String(localized: "Settings", comment: "Settings tab")
        static let error = String(localized: "Error", comment: "Error title")
        static let success = String(localized: "Success", comment: "Success title")
        static let ok = String(localized: "OK", comment: "OK button")
    }
    
    // MARK: - Alarm
    enum Alarm {
        static let title = String(localized: "Alarms", comment: "Alarms tab title")
        static let addNew = String(localized: "Add Alarm", comment: "Add new alarm")
        static let editAlarm = String(localized: "Edit Alarm", comment: "Edit alarm title")
        static let time = String(localized: "Time", comment: "Time label")
        static let label = String(localized: "Label", comment: "Alarm label")
        static let labelPlaceholder = String(localized: "Alarm", comment: "Default alarm label")
        static let sound = String(localized: "Sound", comment: "Sound selection")
        static let snooze = String(localized: "Snooze", comment: "Snooze option")
        static let repeatDays = String(localized: "Repeat", comment: "Repeat days")
        static let once = String(localized: "Once", comment: "One-time alarm")
        static let everyDay = String(localized: "Every day", comment: "Daily alarm")
        static let weekdays = String(localized: "Weekdays", comment: "Weekdays only")
        static let weekends = String(localized: "Weekends", comment: "Weekends only")
        static let noAlarms = String(localized: "No Alarms", comment: "Empty state title")
        static let noAlarmsMessage = String(localized: "Tap + to add your first alarm.\nSnoozing costs money—but it goes to a great cause!", comment: "Empty state message")
        static let active = String(localized: "Active", comment: "Active alarms section")
        static let inactive = String(localized: "Inactive", comment: "Inactive alarms section")
        static let test = String(localized: "Test", comment: "Test alarm button")
    }
    
    // MARK: - Active Alarm View
    enum ActiveAlarm {
        static let snoozeButton = String(localized: "Snooze", comment: "Snooze button")
        static let dismissButton = String(localized: "I'm Awake!", comment: "Dismiss alarm button")
        static let snoozeCost = String(localized: "Snooze Cost", comment: "Snooze cost label")
        static let donatedTo = String(localized: "Donated to Darüşşafaka", comment: "Charity mention")
        static let confirmSnooze = String(localized: "Confirm Snooze", comment: "Confirm snooze title")
        static let snoozeNumber = String(localized: "Snooze #%d", comment: "Snooze count, %d = number")
        static let maxSnoozesReached = String(localized: "Maximum snoozes reached!", comment: "Max snooze warning")
        static let forceWakeUp = String(localized: "Time to wake up! No more snoozing.", comment: "Force wake message")
        
        static func snoozeConfirmMessage(cost: String) -> String {
            String(localized: "You'll be charged \(cost). This donation supports education at Darüşşafaka.", comment: "Snooze confirmation message")
        }
        
        static func payAndSnooze(cost: String) -> String {
            String(localized: "Pay \(cost) & Snooze", comment: "Pay and snooze button")
        }
    }
    
    // MARK: - Impact Dashboard
    enum Impact {
        static let title = String(localized: "Your Impact", comment: "Impact tab title")
        static let totalDonated = String(localized: "Total Donated", comment: "Total donated label")
        static let thisWeek = String(localized: "This Week", comment: "This week label")
        static let thisMonth = String(localized: "This Month", comment: "This month label")
        static let streak = String(localized: "Wake-up Streak", comment: "Streak label")
        static let streakDays = String(localized: "%d days", comment: "Streak days, %d = number")
        static let totalSnoozes = String(localized: "Total Snoozes", comment: "Total snoozes label")
        static let snoozeFreeWakeUps = String(localized: "Snooze-free Wake-ups", comment: "Snooze-free label")
        static let achievements = String(localized: "Achievements", comment: "Achievements section")
        static let shareImpact = String(localized: "Share Your Impact", comment: "Share button")
        static let weeklyActivity = String(localized: "Weekly Activity", comment: "Chart title")
    }
    
    // MARK: - Onboarding
    enum Onboarding {
        static let welcome = String(localized: "Welcome to Snooze If You Can", comment: "Welcome title")
        static let welcomeMessage = String(localized: "The alarm app that turns your snoozes into donations.", comment: "Welcome message")
        static let howItWorks = String(localized: "How It Works", comment: "How it works title")
        static let howItWorksMessage = String(localized: "Every time you hit snooze, a small donation goes to charity. The more you snooze, the more it costs!", comment: "How it works message")
        static let charity = String(localized: "Support Education", comment: "Charity title")
        static let charityMessage = String(localized: "Your donations support students at Darüşşafaka, providing free education to children in need.", comment: "Charity message")
        static let pricing = String(localized: "Escalating Costs", comment: "Pricing title")
        static let pricingMessage = String(localized: "1st snooze: $0.99\n2nd snooze: $1.99\n3rd snooze: $2.99\n4th snooze: $4.99\n5th snooze: $9.99\n\nAfter 5 snoozes, you must wake up!", comment: "Pricing explanation")
        static let permissions = String(localized: "Stay On Track", comment: "Permissions title")
        static let permissionsMessage = String(localized: "We need notification permissions to wake you up on time.", comment: "Permissions message")
        static let getStarted = String(localized: "Get Started", comment: "Get started button")
        static let next = String(localized: "Next", comment: "Next button")
        static let skip = String(localized: "Skip", comment: "Skip button")
        static let enableNotifications = String(localized: "Enable Notifications", comment: "Enable notifications button")
    }
    
    // MARK: - Settings
    enum Settings {
        static let title = String(localized: "Settings", comment: "Settings title")
        static let account = String(localized: "Account", comment: "Account section")
        static let preferences = String(localized: "Preferences", comment: "Preferences section")
        static let sound = String(localized: "Default Sound", comment: "Default sound setting")
        static let vibration = String(localized: "Vibration", comment: "Vibration setting")
        static let volume = String(localized: "Volume", comment: "Volume setting")
        static let increasingVolume = String(localized: "Increasing Volume", comment: "Increasing volume setting")
        static let snoozeMinutes = String(localized: "Snooze Duration", comment: "Snooze duration setting")
        static let about = String(localized: "About", comment: "About section")
        static let charity = String(localized: "About Darüşşafaka", comment: "Charity info")
        static let privacy = String(localized: "Privacy Policy", comment: "Privacy policy")
        static let terms = String(localized: "Terms of Service", comment: "Terms of service")
        static let support = String(localized: "Support", comment: "Support section")
        static let contactUs = String(localized: "Contact Us", comment: "Contact button")
        static let rateApp = String(localized: "Rate the App", comment: "Rate app button")
        static let version = String(localized: "Version %@", comment: "Version label")
        static let icloudSync = String(localized: "iCloud Sync", comment: "iCloud sync setting")
        static let focusMode = String(localized: "Focus Mode Settings", comment: "Focus mode settings")
    }
    
    // MARK: - Social
    enum Social {
        static let title = String(localized: "Social", comment: "Social tab title")
        static let accountabilityPartners = String(localized: "Accountability Partners", comment: "Partners section")
        static let addPartner = String(localized: "Add Partner", comment: "Add partner button")
        static let inviteFriend = String(localized: "Invite a Friend", comment: "Invite button")
        static let yourCircle = String(localized: "Your Circle", comment: "Circle section")
        static let noPartners = String(localized: "No partners yet", comment: "Empty partners")
        static let noPartnersMessage = String(localized: "Add friends to keep each other accountable!", comment: "Empty partners message")
        static let notifyOnSnooze = String(localized: "Notify when I snooze", comment: "Snooze notification toggle")
        static let leaderboard = String(localized: "Leaderboard", comment: "Leaderboard section")
        
        static func friendSnoozed(name: String) -> String {
            String(localized: "\(name) snoozed again 😴", comment: "Friend snoozed notification")
        }
    }
    
    // MARK: - Weekdays
    enum Weekdays {
        static let sunday = String(localized: "Sunday", comment: "Sunday")
        static let monday = String(localized: "Monday", comment: "Monday")
        static let tuesday = String(localized: "Tuesday", comment: "Tuesday")
        static let wednesday = String(localized: "Wednesday", comment: "Wednesday")
        static let thursday = String(localized: "Thursday", comment: "Thursday")
        static let friday = String(localized: "Friday", comment: "Friday")
        static let saturday = String(localized: "Saturday", comment: "Saturday")
        
        static let sunShort = String(localized: "Sun", comment: "Sunday short")
        static let monShort = String(localized: "Mon", comment: "Monday short")
        static let tueShort = String(localized: "Tue", comment: "Tuesday short")
        static let wedShort = String(localized: "Wed", comment: "Wednesday short")
        static let thuShort = String(localized: "Thu", comment: "Thursday short")
        static let friShort = String(localized: "Fri", comment: "Friday short")
        static let satShort = String(localized: "Sat", comment: "Saturday short")
    }
    
    // MARK: - Errors
    enum Errors {
        static let purchaseFailed = String(localized: "Purchase failed. Please try again.", comment: "Purchase error")
        static let networkError = String(localized: "Network error. Please check your connection.", comment: "Network error")
        static let notificationsDenied = String(localized: "Notifications are disabled. Please enable them in Settings to use alarms.", comment: "Notifications denied")
        static let genericError = String(localized: "Something went wrong. Please try again.", comment: "Generic error")
    }
    
    // MARK: - Achievements
    enum Achievements {
        static let earlyBird = String(localized: "Early Bird", comment: "Early bird achievement")
        static let earlyBirdDesc = String(localized: "Dismiss alarm before 6 AM", comment: "Early bird description")
        static let weekWarrior = String(localized: "Week Warrior", comment: "Week warrior achievement")
        static let weekWarriorDesc = String(localized: "7-day snooze-free streak", comment: "Week warrior description")
        static let generousGiver = String(localized: "Generous Giver", comment: "Generous giver achievement")
        static let generousGiverDesc = String(localized: "Donate over $50 total", comment: "Generous giver description")
        static let socialButterfly = String(localized: "Social Butterfly", comment: "Social butterfly achievement")
        static let socialButterflyDesc = String(localized: "Add 5 accountability partners", comment: "Social butterfly description")
    }
}

// MARK: - Currency Formatter

struct CurrencyFormatter {
    static func format(_ amount: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }
    
    /// Format for both USD and TRY (Turkish Lira)
    static func formatDual(_ amountUSD: Double, exchangeRate: Double = 32.0) -> String {
        let usd = format(amountUSD, locale: Locale(identifier: "en_US"))
        let tryAmount = amountUSD * exchangeRate
        let tryFormatted = format(tryAmount, locale: Locale(identifier: "tr_TR"))
        return "\(usd) (~\(tryFormatted))"
    }
}
