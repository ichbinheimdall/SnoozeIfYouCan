import SwiftUI

struct StatsView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // Hero donation card
                    VStack(spacing: 16) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.pink.gradient)
                        
                        Text("Your Impact")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text(alarmManager.stats.formattedTotal)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                        
                        Text("donated to Darüşşafaka")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                    
                    // Stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
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
                    
                    // About Darüşşafaka
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "graduationcap.fill")
                                .foregroundStyle(.blue)
                            Text("About Darüşşafaka")
                                .font(.headline)
                        }
                        
                        Text("""
                            Darüşşafaka Cemiyeti has been providing free education \
                            to orphaned children in Turkey since 1863. Your snooze \
                            donations help fund scholarships, school supplies, and \
                            educational programs.
                            """)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Link(destination: URL(string: "https://www.darussafaka.org")!) {
                            HStack {
                                Text("Learn more")
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Recent snoozes
                    if !alarmManager.snoozeRecords.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Snoozes")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(alarmManager.snoozeRecords.suffix(5).reversed()) { record in
                                HStack {
                                    Image(systemName: "bed.double")
                                        .foregroundStyle(.orange)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading) {
                                        Text(record.dateString)
                                            .font(.subheadline)
                                        Text("Snoozed")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("+$\(String(format: "%.2f", record.amount))")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.green)
                                }
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle("Your Impact")
        }
    }
    
    private var averagePerSnooze: String {
        guard alarmManager.stats.totalSnoozes > 0 else { return "$0.00" }
        let average = alarmManager.stats.totalDonated / Double(alarmManager.stats.totalSnoozes)
        return String(format: "$%.2f", average)
    }
}

#Preview {
    StatsView()
        .environmentObject(AlarmManager())
}
