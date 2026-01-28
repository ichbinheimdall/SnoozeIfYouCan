import SwiftUI
import Combine

/// Achievement/Badge system for gamification
struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let colorHex: String
    let requirement: AchievementRequirement
    var unlockedDate: Date?
    
    var isUnlocked: Bool { unlockedDate != nil }
    
    var color: Color {
        Color(hex: colorHex) ?? .orange
    }
    
    enum AchievementRequirement: Codable, Equatable {
        case streak(days: Int)
        case totalDonated(amount: Double)
        case snoozesFree(count: Int)
        case earlyBird(hour: Int, count: Int)
        case weekendWarrior(count: Int)
        case consistent(days: Int)
        case charitable(amount: Double)
        case firstAlarm
        case socialShare
    }
}

// MARK: - Default Achievements

extension Achievement {
    static let all: [Achievement] = [
        // Streak achievements
        Achievement(
            id: "streak_3",
            title: "Getting Started",
            description: "3 days without snoozing",
            icon: "flame",
            colorHex: "#FF9500",
            requirement: .streak(days: 3)
        ),
        Achievement(
            id: "streak_7",
            title: "Week Warrior",
            description: "7 days without snoozing",
            icon: "flame.fill",
            colorHex: "#FF6B00",
            requirement: .streak(days: 7)
        ),
        Achievement(
            id: "streak_14",
            title: "Fortnight Fighter",
            description: "14 days without snoozing",
            icon: "flame.circle.fill",
            colorHex: "#FF3B30",
            requirement: .streak(days: 14)
        ),
        Achievement(
            id: "streak_30",
            title: "Monthly Master",
            description: "30 days without snoozing",
            icon: "star.fill",
            colorHex: "#FFD700",
            requirement: .streak(days: 30)
        ),
        Achievement(
            id: "streak_100",
            title: "Centurion",
            description: "100 days without snoozing",
            icon: "crown.fill",
            colorHex: "#9B59B6",
            requirement: .streak(days: 100)
        ),
        
        // Donation achievements
        Achievement(
            id: "donated_10",
            title: "First Contribution",
            description: "Donated $10 total",
            icon: "heart",
            colorHex: "#FF2D55",
            requirement: .totalDonated(amount: 10)
        ),
        Achievement(
            id: "donated_50",
            title: "Generous Donor",
            description: "Donated $50 total",
            icon: "heart.fill",
            colorHex: "#FF2D55",
            requirement: .totalDonated(amount: 50)
        ),
        Achievement(
            id: "donated_100",
            title: "Philanthropist",
            description: "Donated $100 total",
            icon: "heart.circle.fill",
            colorHex: "#FF2D55",
            requirement: .totalDonated(amount: 100)
        ),
        Achievement(
            id: "donated_500",
            title: "Champion of Education",
            description: "Donated $500 total",
            icon: "graduationcap.fill",
            colorHex: "#5856D6",
            requirement: .totalDonated(amount: 500)
        ),
        
        // Early bird achievements
        Achievement(
            id: "early_bird_5",
            title: "Early Bird",
            description: "Woke up before 6 AM 5 times",
            icon: "sun.horizon.fill",
            colorHex: "#FFCC00",
            requirement: .earlyBird(hour: 6, count: 5)
        ),
        Achievement(
            id: "early_bird_20",
            title: "Dawn Patrol",
            description: "Woke up before 6 AM 20 times",
            icon: "sunrise.fill",
            colorHex: "#FF9500",
            requirement: .earlyBird(hour: 6, count: 20)
        ),
        
        // Special achievements
        Achievement(
            id: "first_alarm",
            title: "Welcome!",
            description: "Set your first alarm",
            icon: "alarm",
            colorHex: "#34C759",
            requirement: .firstAlarm
        ),
        Achievement(
            id: "weekend_warrior",
            title: "Weekend Warrior",
            description: "No snoozing on 10 weekends",
            icon: "calendar.badge.checkmark",
            colorHex: "#007AFF",
            requirement: .weekendWarrior(count: 10)
        ),
        Achievement(
            id: "social_share",
            title: "Spread the Word",
            description: "Shared your impact with friends",
            icon: "person.2.fill",
            colorHex: "#5AC8FA",
            requirement: .socialShare
        ),
        Achievement(
            id: "consistent_30",
            title: "Consistency King",
            description: "Used the app for 30 consecutive days",
            icon: "checkmark.seal.fill",
            colorHex: "#AF52DE",
            requirement: .consistent(days: 30)
        )
    ]
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}
