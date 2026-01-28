import SwiftUI
import Charts
import Combine

/// Dashboard view showing impact, streaks, and achievements
struct ImpactDashboardView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @StateObject private var achievementManager = AchievementManager()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Hero donation card
                    donationHeroCard
                    
                    // Streak display
                    StreakDisplay(
                        currentStreak: alarmManager.stats.currentStreak,
                        bestStreak: alarmManager.stats.bestStreak
                    )
                    .padding(.horizontal)
                    
                    // Stats grid
                    statsGrid
                    
                    // Weekly chart
                    weeklyDonationChart
                    
                    // Achievements section
                    achievementsSection
                    
                    // About charity
                    charityInfoCard
                    
                    Spacer(minLength: AppTheme.Spacing.huge)
                }
                .padding(.top)
            }
            .navigationTitle("Your Impact")
            .background(AppTheme.Colors.backgroundGrouped)
        }
    }
    
    // MARK: - Hero Card
    
    private var donationHeroCard: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Animated heart icon
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.pink.gradient)
                    .symbolEffect(.pulse)
            }
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Total Donated")
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(alarmManager.stats.formattedTotalDonated)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.pink)
                
                Text("to Darüşşafaka")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxxl)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total donated: \(alarmManager.stats.formattedTotalDonated) to Darüşşafaka")
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: AppTheme.Spacing.md),
            GridItem(.flexible(), spacing: AppTheme.Spacing.md)
        ], spacing: AppTheme.Spacing.md) {
            StatCard(
                title: "Total Snoozes",
                value: "\(alarmManager.stats.totalSnoozes)",
                icon: "bed.double.fill",
                color: .orange
            )
            
            StatCard(
                title: "This Week",
                value: String(format: "$%.2f", alarmManager.stats.currentWeekAmount),
                icon: "calendar",
                color: .blue
            )
            
            StatCard(
                title: "This Month",
                value: String(format: "$%.2f", alarmManager.stats.currentMonthAmount),
                icon: "calendar.badge.clock",
                color: .purple
            )
            
            StatCard(
                title: "Avg per Snooze",
                value: averagePerSnooze,
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
        }
        .padding(.horizontal)
    }
    
    private var averagePerSnooze: String {
        guard alarmManager.stats.totalSnoozes > 0 else { return "$0.00" }
        let average = alarmManager.stats.totalDonated / Double(alarmManager.stats.totalSnoozes)
        return String(format: "$%.2f", average)
    }
    
    // MARK: - Weekly Chart
    
    private var weeklyDonationChart: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("This Week")
                .font(AppTheme.Typography.headline)
                .padding(.horizontal)
            
            // Simple bar chart using Swift Charts
            Chart {
                ForEach(weeklyData, id: \.day) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Amount", data.amount)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(Int(amount))")
                                .font(.caption2)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .padding(.horizontal)
    }
    
    // Sample weekly data - in production, calculate from snoozeRecords
    private var weeklyData: [DayData] {
        [
            DayData(day: "Mon", amount: 2.50),
            DayData(day: "Tue", amount: 1.00),
            DayData(day: "Wed", amount: 0.00),
            DayData(day: "Thu", amount: 3.00),
            DayData(day: "Fri", amount: 1.50),
            DayData(day: "Sat", amount: 0.00),
            DayData(day: "Sun", amount: 2.00)
        ]
    }
    
    // MARK: - Achievements Section
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Achievements")
                    .font(AppTheme.Typography.headline)
                
                Spacer()
                
                NavigationLink {
                    AllAchievementsView(achievementManager: achievementManager)
                } label: {
                    Text("See All")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.lg) {
                    ForEach(Achievement.all.prefix(5)) { achievement in
                        AchievementBadge(
                            achievement: achievement,
                            isUnlocked: achievementManager.isUnlocked(achievement)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Charity Info Card
    
    private var charityInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(.blue)
                    .font(.title2)
                
                Text("About Darüşşafaka")
                    .font(AppTheme.Typography.headline)
            }
            
            Text("""
                Darüşşafaka Cemiyeti has been providing free, high-quality education \
                to orphaned children in Turkey since 1863. Your snooze donations help \
                fund scholarships, school supplies, and educational programs.
                """)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            Link(destination: URL(string: "https://www.darussafaka.org")!) {
                HStack {
                    Text("Learn more")
                    Image(systemName: "arrow.up.right")
                }
                .font(AppTheme.Typography.subheadline.bold())
                .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .padding(.horizontal)
    }
}

// MARK: - Supporting Types

struct DayData {
    let day: String
    let amount: Double
}

// MARK: - All Achievements View

struct AllAchievementsView: View {
    @ObservedObject var achievementManager: AchievementManager
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.xl) {
                ForEach(Achievement.all) { achievement in
                    VStack(spacing: AppTheme.Spacing.sm) {
                        AchievementBadge(
                            achievement: achievement,
                            isUnlocked: achievementManager.isUnlocked(achievement)
                        )
                        
                        Text(achievement.description)
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Achievement Manager

@MainActor
class AchievementManager: ObservableObject {
    @Published var unlockedIds: Set<String> = []
    
    private let key = "unlocked_achievements"
    
    init() {
        loadUnlocked()
    }
    
    func isUnlocked(_ achievement: Achievement) -> Bool {
        unlockedIds.contains(achievement.id)
    }
    
    func unlock(_ achievement: Achievement) {
        guard !isUnlocked(achievement) else { return }
        unlockedIds.insert(achievement.id)
        saveUnlocked()
        
        // Haptic feedback
        HapticsManager.shared.achievementUnlocked()
    }
    
    func checkAchievements(stats: DonationStats, userStats: UserStats) {
        for achievement in Achievement.all {
            if shouldUnlock(achievement, stats: stats, userStats: userStats) {
                unlock(achievement)
            }
        }
    }
    
    private func shouldUnlock(_ achievement: Achievement, stats: DonationStats, userStats: UserStats) -> Bool {
        guard !isUnlocked(achievement) else { return false }
        
        switch achievement.requirement {
        case .streak(let days):
            return userStats.currentStreak >= days
        case .totalDonated(let amount):
            return stats.totalDonated >= amount
        case .snoozesFree(let count):
            return userStats.snoozeFreeWakeUps >= count
        case .earlyBird(_, let count):
            return userStats.earlyBirdCount >= count
        case .weekendWarrior(let count):
            return userStats.weekendNoSnoozeCount >= count
        case .consistent(let days):
            return userStats.consecutiveUseDays >= days
        case .charitable(let amount):
            return stats.totalDonated >= amount
        case .firstAlarm:
            return true // Unlocked when first alarm is set
        case .socialShare:
            return userStats.hasSharedImpact
        }
    }
    
    private func saveUnlocked() {
        UserDefaults.standard.set(Array(unlockedIds), forKey: key)
    }
    
    private func loadUnlocked() {
        if let ids = UserDefaults.standard.array(forKey: key) as? [String] {
            unlockedIds = Set(ids)
        }
    }
}

// MARK: - Preview

#Preview("Impact Dashboard") {
    ImpactDashboardView()
        .environmentObject(AlarmManager())
}
