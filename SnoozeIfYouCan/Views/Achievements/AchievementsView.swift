import SwiftUI

// MARK: - Achievements View

struct AchievementsView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var selectedAchievement: Achievement?
    @State private var showConfetti = false
    @State private var animateUnlocked = false
    
    private var unlockedAchievements: [Achievement] {
        Achievement.all.filter { achievement in
            isAchievementUnlocked(achievement)
        }
    }
    
    private var lockedAchievements: [Achievement] {
        Achievement.all.filter { achievement in
            !isAchievementUnlocked(achievement)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress Header
                    ProgressHeaderView(
                        unlockedCount: unlockedAchievements.count,
                        totalCount: Achievement.all.count
                    )
                    
                    // Unlocked Section
                    if !unlockedAchievements.isEmpty {
                        AchievementSection(
                            title: "Unlocked",
                            achievements: unlockedAchievements,
                            isUnlocked: true,
                            selectedAchievement: $selectedAchievement,
                            animate: animateUnlocked
                        )
                    }
                    
                    // Locked Section
                    if !lockedAchievements.isEmpty {
                        AchievementSection(
                            title: "In Progress",
                            achievements: lockedAchievements,
                            isUnlocked: false,
                            selectedAchievement: $selectedAchievement,
                            stats: alarmManager.stats
                        )
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Achievements")
            .sheet(item: $selectedAchievement) { achievement in
                AchievementDetailSheet(
                    achievement: achievement,
                    isUnlocked: isAchievementUnlocked(achievement),
                    stats: alarmManager.stats
                )
                .presentationDetents([.medium])
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                    animateUnlocked = true
                }
            }
        }
    }
    
    private func isAchievementUnlocked(_ achievement: Achievement) -> Bool {
        let stats = alarmManager.stats
        
        switch achievement.requirement {
        case .streak(let days):
            return stats.longestStreak >= days
        case .totalDonated(let amount):
            return stats.totalDonated >= amount
        case .snoozesFree(_):
            return stats.currentStreak >= 1
        case .earlyBird(_, _):
            // Would need to track early wakeups
            return false
        case .weekendWarrior(_):
            // Would need to track weekend performance
            return false
        case .consistent(let days):
            return stats.currentStreak >= days
        case .charitable(let amount):
            return stats.totalDonated >= amount
        case .firstAlarm:
            return true // Always unlocked if user has the app
        case .socialShare:
            return UserDefaults.standard.bool(forKey: "has_shared_socially")
        }
    }
}

// MARK: - Progress Header

struct ProgressHeaderView: View {
    let unlockedCount: Int
    let totalCount: Int
    
    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(unlockedCount)/\(totalCount)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Achievements Unlocked")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "trophy.fill")
                        .font(.title)
                        .foregroundStyle(.orange)
                }
                .frame(width: 80, height: 80)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                    
                    Capsule()
                        .fill(Color.orange.gradient)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        .padding(.horizontal)
    }
}

// MARK: - Achievement Section

struct AchievementSection: View {
    let title: String
    let achievements: [Achievement]
    let isUnlocked: Bool
    @Binding var selectedAchievement: Achievement?
    var animate: Bool = false
    var stats: DonationStats? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(achievements.enumerated()), id: \.element.id) { index, achievement in
                    AchievementBadge(
                        achievement: achievement,
                        isUnlocked: isUnlocked,
                        progress: calculateProgress(for: achievement),
                        animate: animate,
                        animationDelay: Double(index) * 0.1
                    )
                    .onTapGesture {
                        selectedAchievement = achievement
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func calculateProgress(for achievement: Achievement) -> Double {
        guard let stats = stats else { return 0 }
        
        switch achievement.requirement {
        case .streak(let days):
            return min(1.0, Double(stats.currentStreak) / Double(days))
        case .totalDonated(let amount):
            return min(1.0, stats.totalDonated / amount)
        case .snoozesFree(let count):
            return min(1.0, Double(stats.currentStreak) / Double(count))
        case .consistent(let days):
            return min(1.0, Double(stats.currentStreak) / Double(days))
        case .charitable(let amount):
            return min(1.0, stats.totalDonated / amount)
        default:
            return 0
        }
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let stats: DonationStats
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Badge
            ZStack {
                Circle()
                    .fill(achievement.color.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(isUnlocked ? achievement.color : .gray)
                
                if isUnlocked {
                    Circle()
                        .stroke(achievement.color, lineWidth: 4)
                        .frame(width: 120, height: 120)
                }
            }
            .padding(.top)
            
            // Title and description
            VStack(spacing: 8) {
                Text(achievement.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(achievement.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Progress or unlock info
            if isUnlocked {
                Label("Achievement Unlocked!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                VStack(spacing: 8) {
                    Text("Progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ProgressView(value: calculateProgress())
                        .progressViewStyle(.linear)
                        .tint(achievement.color)
                        .frame(width: 200)
                    
                    Text(progressText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(achievement.color)
        }
        .padding()
    }
    
    private func calculateProgress() -> Double {
        switch achievement.requirement {
        case .streak(let days):
            return min(1.0, Double(stats.currentStreak) / Double(days))
        case .totalDonated(let amount):
            return min(1.0, stats.totalDonated / amount)
        case .snoozesFree(let count):
            return min(1.0, Double(stats.currentStreak) / Double(count))
        case .consistent(let days):
            return min(1.0, Double(stats.currentStreak) / Double(days))
        case .charitable(let amount):
            return min(1.0, stats.totalDonated / amount)
        default:
            return 0
        }
    }
    
    private var progressText: String {
        switch achievement.requirement {
        case .streak(let days):
            return "\(stats.currentStreak)/\(days) days"
        case .totalDonated(let amount):
            return "$\(String(format: "%.2f", stats.totalDonated))/$\(Int(amount))"
        case .snoozesFree(let count):
            return "\(stats.currentStreak)/\(count) snooze-free"
        case .consistent(let days):
            return "\(stats.currentStreak)/\(days) days"
        case .charitable(let amount):
            return "$\(String(format: "%.2f", stats.totalDonated))/$\(Int(amount))"
        default:
            return "In progress"
        }
    }
}

// MARK: - Preview

#Preview {
    AchievementsView()
        .environmentObject(AlarmManager())
}
