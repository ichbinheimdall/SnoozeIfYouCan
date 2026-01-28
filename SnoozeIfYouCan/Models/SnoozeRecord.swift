import Foundation

struct SnoozeRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var alarmId: UUID
    var date: Date
    var amount: Double
    var donated: Bool = false
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DonationStats: Codable {
    var totalDonated: Double = 0
    var totalSnoozes: Int = 0
    var snoozeFreeWakeUps: Int = 0
    
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastStreakDate: Date?
    
    var currentWeekAmount: Double = 0
    var currentMonthAmount: Double = 0
    var weekStartDate: Date?
    var monthStartDate: Date?
    
    var formattedTotal: String {
        String(format: "$%.2f", totalDonated)
    }
    
    // Alias for compatibility
    var formattedTotalDonated: String {
        formattedTotal
    }
    
    // Alias for compatibility
    var bestStreak: Int {
        longestStreak
    }
    
    var formattedWeekly: String {
        String(format: "$%.2f", currentWeekAmount)
    }
    
    var formattedMonthly: String {
        String(format: "$%.2f", currentMonthAmount)
    }
}
