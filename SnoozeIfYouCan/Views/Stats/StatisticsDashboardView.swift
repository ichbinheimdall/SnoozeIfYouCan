import SwiftUI
import Charts

// MARK: - Statistics Dashboard View

struct StatisticsDashboardView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var charityManager: CharityManager
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var animateCharts = false
    
    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case year = "Year"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Overview Cards
                    OverviewCardsSection(stats: alarmManager.stats)
                    
                    // Donation Chart
                    DonationChartSection(
                        records: alarmManager.snoozeRecords,
                        timeRange: selectedTimeRange,
                        animate: animateCharts
                    )
                    
                    // Wake Up Performance
                    WakeUpPerformanceSection(stats: alarmManager.stats)
                    
                    // Snooze Patterns
                    SnoozePatternSection(records: alarmManager.snoozeRecords)
                    
                    // Charity Impact
                    CharityImpactSection(charityManager: charityManager)
                    
                    // Weekly Comparison
                    WeeklyComparisonSection(records: alarmManager.snoozeRecords)
                }
                .padding(.vertical)
            }
            .navigationTitle("Statistics")
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animateCharts = true
                }
            }
        }
    }
}

// MARK: - Overview Cards Section

struct OverviewCardsSection: View {
    let stats: DonationStats
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Total Donated",
                value: "$\(String(format: "%.2f", stats.totalDonated))",
                icon: "heart.fill",
                color: .pink
            )
            
            StatCard(
                title: "Current Streak",
                value: "\(stats.currentStreak) days",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                title: "Total Snoozes",
                value: "\(stats.totalSnoozes)",
                icon: "bed.double.fill",
                color: .purple
            )
            
            StatCard(
                title: "Best Streak",
                value: "\(stats.longestStreak) days",
                icon: "trophy.fill",
                color: .yellow
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Donation Chart Section

struct DonationChartSection: View {
    let records: [SnoozeRecord]
    let timeRange: StatisticsDashboardView.TimeRange
    let animate: Bool
    
    private var chartData: [DonationDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        
        switch timeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: now)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        case .allTime:
            startDate = records.map(\.date).min() ?? now
        }
        
        let filteredRecords = records.filter { $0.date >= startDate }
        
        var grouped: [Date: Double] = [:]
        for record in filteredRecords {
            let key = calendar.startOfDay(for: record.date)
            grouped[key, default: 0] += record.amount
        }
        
        return grouped.map { DonationDataPoint(date: $0.key, amount: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Donations Over Time")
                .font(.headline)
                .padding(.horizontal)
            
            if chartData.isEmpty {
                EmptyChartPlaceholder(message: "No donation data yet")
            } else {
                Chart(chartData) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Amount", animate ? point.amount : 0)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("$\(Int(amount))")
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        .padding(.horizontal)
    }
}

struct DonationDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

// MARK: - Wake Up Performance Section

struct WakeUpPerformanceSection: View {
    let stats: DonationStats
    
    private var wakeUpRate: Double {
        let total = Double(stats.totalSnoozes + stats.currentStreak)
        guard total > 0 else { return 0 }
        return Double(stats.currentStreak) / total * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wake Up Performance")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                // Gauge
                Gauge(value: wakeUpRate, in: 0...100) {
                    Text("Success")
                } currentValueLabel: {
                    Text("\(Int(wakeUpRate))%")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.red, .orange, .green]))
                .scaleEffect(1.5)
                .frame(width: 100)
                
                VStack(alignment: .leading, spacing: 8) {
                    PerformanceRow(
                        label: "Woke up on time",
                        value: "\(stats.currentStreak)",
                        color: .green
                    )
                    PerformanceRow(
                        label: "Snoozed",
                        value: "\(stats.totalSnoozes)",
                        color: .orange
                    )
                    PerformanceRow(
                        label: "Best streak",
                        value: "\(stats.longestStreak) days",
                        color: .blue
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        .padding(.horizontal)
    }
}

struct PerformanceRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Snooze Pattern Section

struct SnoozePatternSection: View {
    let records: [SnoozeRecord]
    
    private var snoozesByHour: [Int: Int] {
        var counts: [Int: Int] = [:]
        let calendar = Calendar.current
        
        for record in records {
            let hour = calendar.component(.hour, from: record.date)
            counts[hour, default: 0] += 1
        }
        
        return counts
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Snooze Patterns")
                .font(.headline)
                .padding(.horizontal)
            
            if records.isEmpty {
                EmptyChartPlaceholder(message: "No snooze data yet")
            } else {
                Chart {
                    ForEach(0..<24, id: \.self) { hour in
                        BarMark(
                            x: .value("Hour", hour),
                            y: .value("Count", snoozesByHour[hour] ?? 0)
                        )
                        .foregroundStyle(Color.purple.gradient)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                        AxisValueLabel {
                            if let hour = value.as(Int.self) {
                                Text(formatHour(hour))
                            }
                        }
                    }
                }
                .frame(height: 150)
                .padding(.horizontal)
            }
            
            Text("When you snooze most")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        .padding(.horizontal)
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}

// MARK: - Charity Impact Section

struct CharityImpactSection: View {
    @ObservedObject var charityManager: CharityManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Charity Impact")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Current charity
                HStack {
                    Image(systemName: charityManager.selectedCharity.category.icon)
                        .font(.title)
                        .foregroundStyle(charityManager.selectedCharity.color)
                    
                    VStack(alignment: .leading) {
                        Text(charityManager.selectedCharity.shortName)
                            .font(.headline)
                        Text("Currently supporting")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(String(format: "%.2f", charityManager.totalDonated(to: charityManager.selectedCharity)))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(charityManager.selectedCharity.color)
                        Text("donated")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                // Total across all charities
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .font(.title)
                        .foregroundStyle(.pink)
                    
                    Text("Total Impact")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", charityManager.totalDonatedAllCharities))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.pink)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        .padding(.horizontal)
    }
}

// MARK: - Weekly Comparison Section

struct WeeklyComparisonSection: View {
    let records: [SnoozeRecord]
    
    private var weekdayData: [WeekdayData] {
        var counts: [Int: (snoozes: Int, amount: Double)] = [:]
        let calendar = Calendar.current
        
        for record in records {
            let weekday = calendar.component(.weekday, from: record.date)
            let current = counts[weekday] ?? (0, 0)
            counts[weekday] = (current.snoozes + 1, current.amount + record.amount)
        }
        
        return (1...7).map { weekday in
            let data = counts[weekday] ?? (0, 0)
            return WeekdayData(
                weekday: weekday,
                snoozes: data.snoozes,
                amount: data.amount
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Snoozes by Day")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(weekdayData) { data in
                BarMark(
                    x: .value("Day", data.dayName),
                    y: .value("Snoozes", data.snoozes)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 150)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        .padding(.horizontal)
    }
}

struct WeekdayData: Identifiable {
    let id = UUID()
    let weekday: Int
    let snoozes: Int
    let amount: Double
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let date = Calendar.current.date(bySetting: .weekday, value: weekday, of: Date())!
        return formatter.string(from: date)
    }
}

// MARK: - Empty Placeholder

struct EmptyChartPlaceholder: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    StatisticsDashboardView()
        .environmentObject(AlarmManager())
        .environmentObject(CharityManager.shared)
}
