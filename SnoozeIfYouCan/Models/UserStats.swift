import Foundation

/// Comprehensive user statistics for streaks, achievements, and social features
struct UserStats: Codable {
    // Streak data
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var lastWakeUpDate: Date?
    
    // Donation stats
    var totalDonated: Double = 0
    var totalSnoozes: Int = 0
    var snoozeFreeWakeUps: Int = 0
    
    // Time-based stats
    var currentWeekDonated: Double = 0
    var currentMonthDonated: Double = 0
    var weekStartDate: Date?
    var monthStartDate: Date?
    
    // Achievement tracking
    var unlockedAchievementIds: Set<String> = []
    var earlyBirdCount: Int = 0
    var weekendNoSnoozeCount: Int = 0
    var consecutiveUseDays: Int = 0
    var lastAppUseDate: Date?
    
    // Social
    var hasSharedImpact: Bool = false
    var friendsInvited: Int = 0
    
    // Computed properties
    var totalWakeUps: Int {
        totalSnoozes + snoozeFreeWakeUps
    }
    
    var snoozeRate: Double {
        guard totalWakeUps > 0 else { return 0 }
        return Double(totalSnoozes) / Double(totalWakeUps) * 100
    }
    
    var averageDonationPerSnooze: Double {
        guard totalSnoozes > 0 else { return 0 }
        return totalDonated / Double(totalSnoozes)
    }
    
    var formattedTotalDonated: String {
        String(format: "$%.2f", totalDonated)
    }
}

// MARK: - Social Accountability

struct AccountabilityPartner: Identifiable, Codable {
    let id: UUID
    var name: String
    var phoneNumber: String?
    var email: String?
    var notifyOnSnooze: Bool = true
    var notifyOnStreak: Bool = true
    
    init(id: UUID = UUID(), name: String, phoneNumber: String? = nil, email: String? = nil) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
    }
}

struct SnoozeNotification: Codable {
    let date: Date
    let alarmTime: Date
    let snoozeCost: Double
    let partnerNotified: Bool
}
