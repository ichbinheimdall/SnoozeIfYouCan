import SwiftUI
import Combine

/// Comprehensive settings view following Apple HIG
struct SettingsView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var soundManager: SoundManager
    @EnvironmentObject var hapticsManager: HapticsManager
    
    // Settings
    @AppStorage("defaultSnoozeCost") private var defaultSnoozeCost: Double = 1.0
    @AppStorage("snoozeDuration") private var snoozeDuration: Int = 5
    
    @State private var showingResetAlert = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            List {
                // Alarm Defaults
                alarmDefaultsSection
                
                // Sound & Haptics
                soundHapticsSection
                
                // Notifications
                notificationsSection
                
                // Charity Partner
                charitySection
                
                // Data & Privacy
                dataSection
                
                // About
                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
        }
    }
    
    // MARK: - Alarm Defaults Section
    
    private var alarmDefaultsSection: some View {
        Section {
            // Default snooze cost
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text("Default Snooze Cost")
                    Spacer()
                    Text("$\(String(format: "%.2f", defaultSnoozeCost))")
                        .foregroundStyle(.orange)
                        .fontWeight(.semibold)
                }
                
                Slider(value: $defaultSnoozeCost, in: 0.5...10, step: 0.5)
                    .tint(.orange)
                    .onChange(of: defaultSnoozeCost) { _, _ in
                        HapticsManager.shared.selectionChanged()
                    }
            }
            .padding(.vertical, AppTheme.Spacing.xxs)
            
            // Snooze duration
            Picker("Snooze Duration", selection: $snoozeDuration) {
                Text("1 minute").tag(1)
                Text("3 minutes").tag(3)
                Text("5 minutes").tag(5)
                Text("10 minutes").tag(10)
                Text("15 minutes").tag(15)
            }
            .onChange(of: snoozeDuration) { _, _ in
                HapticsManager.shared.selectionChanged()
            }
        } header: {
            Label("Alarm Defaults", systemImage: "alarm")
        } footer: {
            Text("These settings apply to new alarms. Existing alarms keep their settings.")
        }
    }
    
    // MARK: - Sound & Haptics Section
    
    private var soundHapticsSection: some View {
        Section {
            // Default sound
            NavigationLink {
                SoundPickerView()
            } label: {
                HStack {
                    Text("Default Sound")
                    Spacer()
                    Text(soundManager.selectedSound.name)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            
            // Volume
            Picker("Volume", selection: $soundManager.volume) {
                ForEach(AlarmVolume.allCases, id: \.self) { volume in
                    Text(volume.displayName).tag(volume)
                }
            }
            
            // Increasing volume
            Toggle("Gradually Increase Volume", isOn: $soundManager.increasingVolume)
                .tint(.orange)
            
            // Vibration
            Toggle("Vibration", isOn: $soundManager.vibrationEnabled)
                .tint(.orange)
            
            // Haptic feedback
            Toggle("Haptic Feedback", isOn: $hapticsManager.isEnabled)
                .tint(.orange)
        } header: {
            Label("Sound & Haptics", systemImage: "speaker.wave.3")
        } footer: {
            Text("Haptic feedback provides tactile responses throughout the app.")
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        Section {
            Button {
                openNotificationSettings()
            } label: {
                HStack {
                    Label("Notification Settings", systemImage: "bell.badge")
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
            
            // Show notification status
            HStack {
                Text("Status")
                Spacer()
                NotificationStatusBadge()
            }
        } header: {
            Label("Notifications", systemImage: "bell")
        } footer: {
            Text("Notifications must be enabled for alarms to work properly.")
        }
    }
    
    // MARK: - Charity Section
    
    private var charitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    // Logo placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "graduationcap.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                        Text("Darüşşafaka")
                            .font(AppTheme.Typography.headline)
                        Text("Education for children since 1863")
                            .font(AppTheme.Typography.caption1)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                
                Text("""
                    100% of your snooze fees are donated to Darüşşafaka Cemiyeti, \
                    which provides free education to orphaned children in Turkey.
                    """)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                
                Link(destination: URL(string: "https://www.darussafaka.org")!) {
                    HStack {
                        Text("Visit Website")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(AppTheme.Typography.subheadline.bold())
                    .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, AppTheme.Spacing.xs)
        } header: {
            Label("Charity Partner", systemImage: "heart")
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        Section {
            // Export data
            Button {
                exportData()
            } label: {
                Label("Export My Data", systemImage: "square.and.arrow.up")
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            
            // Reset statistics
            Button(role: .destructive) {
                showingResetAlert = true
            } label: {
                Label("Reset Statistics", systemImage: "arrow.counterclockwise")
            }
        } header: {
            Label("Data & Privacy", systemImage: "lock.shield")
        } footer: {
            Text("Resetting statistics won't affect your actual donations.")
        }
        .alert("Reset Statistics?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetStatistics()
            }
        } message: {
            Text("This will reset all your snooze statistics. Your donation history remains in the App Store.")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0 (1)")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            
            NavigationLink {
                AboutView()
            } label: {
                Text("About Snooze If You Can")
            }
            
            Link(destination: URL(string: "mailto:hello@snoozeifyoucan.app")!) {
                Label("Contact Support", systemImage: "envelope")
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            
            Link(destination: URL(string: "https://snoozeifyoucan.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            
            Link(destination: URL(string: "https://snoozeifyoucan.app/terms")!) {
                Label("Terms of Service", systemImage: "doc.text")
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
        } header: {
            Label("About", systemImage: "info.circle")
        }
    }
    
    // MARK: - Actions
    
    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Export user data (snooze records, statistics) to JSON format
    /// Future enhancement: Add CSV export option and share sheet
    private func exportData() {
        let exportData: [String: Any] = [
            "alarms": alarmManager.alarms.map { alarm in
                [
                    "id": alarm.id.uuidString,
                    "time": alarm.timeString,
                    "label": alarm.label,
                    "isEnabled": alarm.isEnabled,
                    "repeatDays": alarm.repeatDays.map { $0.rawValue }
                ]
            },
            "snoozeRecords": alarmManager.snoozeRecords.map { record in
                [
                    "alarmId": record.alarmId.uuidString,
                    "date": ISO8601DateFormatter().string(from: record.date),
                    "amount": record.amount
                ]
            },
            "statistics": [
                "totalDonated": alarmManager.stats.totalDonated,
                "totalSnoozes": alarmManager.stats.totalSnoozes,
                "currentStreak": alarmManager.stats.currentStreak,
                "longestStreak": alarmManager.stats.longestStreak
            ],
            "exportDate": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Convert to JSON and copy to clipboard as temporary solution
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UIPasteboard.general.string = jsonString
            HapticsManager.shared.success()
            // Note: In production, this should use share sheet or save to Files
        }
    }
    
    private func resetStatistics() {
        // Reset stats in alarm manager
        alarmManager.stats = DonationStats()
        HapticsManager.shared.mediumTap()
    }
}

// MARK: - Notification Status Badge

struct NotificationStatusBadge: View {
    @State private var status: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(AppTheme.Typography.caption1)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .onAppear {
            checkStatus()
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        @unknown default: return .gray
        }
    }
    
    private var statusText: String {
        switch status {
        case .authorized, .provisional, .ephemeral: return "Enabled"
        case .denied: return "Disabled"
        case .notDetermined: return "Not Set"
        @unknown default: return "Unknown"
        }
    }
    
    private func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                status = settings.authorizationStatus
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xxl) {
                // App icon placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.orange.gradient)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }
                .padding(.top, AppTheme.Spacing.xxl)
                
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Snooze If You Can")
                        .font(AppTheme.Typography.title1)
                    
                    Text("Wake up for a good cause")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                Divider()
                    .padding(.horizontal, AppTheme.Spacing.xxxl)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    Text("About")
                        .font(AppTheme.Typography.headline)
                    
                    Text("""
                        Snooze If You Can is an alarm app with a twist: every time you \
                        hit snooze, you make a small donation to Darüşşafaka, helping \
                        provide education to children in need.
                        
                        The cost escalates with each snooze, creating real motivation \
                        to wake up—while ensuring that if you do sleep in, at least \
                        it's for a good cause.
                        
                        We believe waking up should be meaningful. Every snooze helps \
                        a child get the education they deserve.
                        """)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    Text("Credits")
                        .font(AppTheme.Typography.headline)
                    
                    Text("""
                        Created with ❤️ for Darüşşafaka
                        
                        Built with SwiftUI
                        Icons by SF Symbols
                        """)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                Spacer(minLength: AppTheme.Spacing.huge)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("Settings") {
    SettingsView()
        .environmentObject(AlarmManager())
        .environmentObject(SoundManager.shared)
        .environmentObject(HapticsManager.shared)
}
