import SwiftUI
import MessageUI
import Combine

/// Social accountability features - sharing and partner notifications
struct SocialAccountabilityView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @StateObject private var viewModel = SocialAccountabilityViewModel()
    
    @State private var showingAddPartner = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                // Impact Summary Card
                Section {
                    ImpactShareCard(stats: alarmManager.stats)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                
                // Share Your Impact
                Section {
                    Button {
                        HapticsManager.shared.mediumTap()
                        showingShareSheet = true
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text("Share Your Impact")
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Text("Let friends know about your progress")
                                    .font(AppTheme.Typography.caption1)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    Button {
                        HapticsManager.shared.mediumTap()
                        inviteFriend()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text("Invite a Friend")
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Text("Help them wake up for a good cause")
                                    .font(AppTheme.Typography.caption1)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                        } icon: {
                            Image(systemName: "person.badge.plus")
                                .foregroundStyle(.blue)
                        }
                    }
                } header: {
                    Text("Spread the Word")
                }
                
                // Accountability Partners
                Section {
                    if viewModel.partners.isEmpty {
                        VStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "person.2.slash")
                                .font(.largeTitle)
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                            Text("No accountability partners yet")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                            Text("Add someone who'll keep you honest!")
                                .font(AppTheme.Typography.caption1)
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.xl)
                    } else {
                        ForEach(viewModel.partners) { partner in
                            PartnerRow(partner: partner)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.removePartner(partner)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    
                    Button {
                        HapticsManager.shared.lightTap()
                        showingAddPartner = true
                    } label: {
                        Label("Add Accountability Partner", systemImage: "plus.circle.fill")
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Accountability Partners")
                } footer: {
                    Text("Partners can be notified when you snooze. They'll hold you accountable!")
                }
                
                // Notification Settings
                Section {
                    Toggle("Notify partners on snooze", isOn: $viewModel.notifyOnSnooze)
                        .tint(.orange)
                    
                    Toggle("Notify partners on streaks", isOn: $viewModel.notifyOnStreak)
                        .tint(.orange)
                    
                    Toggle("Weekly summary to partners", isOn: $viewModel.sendWeeklySummary)
                        .tint(.orange)
                } header: {
                    Text("Partner Notifications")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Social")
            .sheet(isPresented: $showingAddPartner) {
                AddPartnerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [createShareContent()])
            }
        }
    }
    
    private func createShareContent() -> String {
        """
        🌅 I've been using Snooze If You Can to wake up better!
        
        💰 Total donated: \(alarmManager.stats.formattedTotalDonated)
        🔥 Current streak: \(alarmManager.stats.currentStreak) days
        📚 Supporting education at Darüşşafaka
        
        Join me in waking up for a good cause!
        """
    }
    
    private func inviteFriend() {
        // Trigger share sheet with app invite
        showingShareSheet = true
    }
}

// MARK: - Impact Share Card

struct ImpactShareCard: View {
    let stats: DonationStats
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.xxl) {
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text(stats.formattedTotal)
                        .font(AppTheme.Typography.title1)
                        .foregroundStyle(.orange)
                    Text("Donated")
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                Divider().frame(height: 40)
                
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("\(stats.totalSnoozes)")
                        .font(AppTheme.Typography.title1)
                    Text("Snoozes")
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            
            // Charity branding
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(.blue)
                Text("Supporting Darüşşafaka")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .padding(.horizontal)
    }
}

// MARK: - Partner Row

struct PartnerRow: View {
    let partner: AccountabilityPartner
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Text(partner.name.prefix(1).uppercased())
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.orange)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(partner.name)
                    .font(AppTheme.Typography.body)
                
                HStack(spacing: AppTheme.Spacing.sm) {
                    if partner.notifyOnSnooze {
                        Label("Snooze alerts", systemImage: "bell.fill")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                    if partner.notifyOnStreak {
                        Label("Streak alerts", systemImage: "flame.fill")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

// MARK: - Add Partner View

struct AddPartnerView: View {
    @ObservedObject var viewModel: SocialAccountabilityViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var notifyOnSnooze = true
    @State private var notifyOnStreak = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Phone (optional)", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    
                    TextField("Email (optional)", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Contact Info")
                }
                
                Section {
                    Toggle("Notify when I snooze", isOn: $notifyOnSnooze)
                        .tint(.orange)
                    
                    Toggle("Notify on streak milestones", isOn: $notifyOnStreak)
                        .tint(.orange)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Your partner will receive messages when you hit snooze or reach streak milestones.")
                }
            }
            .navigationTitle("Add Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addPartner()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func addPartner() {
        var partner = AccountabilityPartner(
            name: name,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            email: email.isEmpty ? nil : email
        )
        partner.notifyOnSnooze = notifyOnSnooze
        partner.notifyOnStreak = notifyOnStreak
        
        viewModel.addPartner(partner)
        HapticsManager.shared.success()
        dismiss()
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - View Model

@MainActor
class SocialAccountabilityViewModel: ObservableObject {
    @Published var partners: [AccountabilityPartner] = []
    @Published var notifyOnSnooze = true
    @Published var notifyOnStreak = true
    @Published var sendWeeklySummary = false
    
    private let partnersKey = "accountability_partners"
    
    init() {
        loadPartners()
        loadSettings()
    }
    
    func addPartner(_ partner: AccountabilityPartner) {
        partners.append(partner)
        savePartners()
    }
    
    func removePartner(_ partner: AccountabilityPartner) {
        partners.removeAll { $0.id == partner.id }
        savePartners()
    }
    
    private func savePartners() {
        if let data = try? JSONEncoder().encode(partners) {
            UserDefaults.standard.set(data, forKey: partnersKey)
        }
    }
    
    private func loadPartners() {
        if let data = UserDefaults.standard.data(forKey: partnersKey),
           let decoded = try? JSONDecoder().decode([AccountabilityPartner].self, from: data) {
            partners = decoded
        }
    }
    
    private func loadSettings() {
        notifyOnSnooze = UserDefaults.standard.object(forKey: "notify_partners_snooze") as? Bool ?? true
        notifyOnStreak = UserDefaults.standard.object(forKey: "notify_partners_streak") as? Bool ?? true
        sendWeeklySummary = UserDefaults.standard.object(forKey: "send_weekly_summary") as? Bool ?? false
    }
    
    func notifyPartners(about event: PartnerNotificationEvent) {
        // In production, this would send SMS/email via a backend service
        // For now, we'll log and potentially use MessageUI
        for partner in partners {
            switch event {
            case .snoozed(let cost):
                if partner.notifyOnSnooze {
                    print("📱 Notifying \(partner.name): Snoozed for $\(cost)")
                }
            case .streakReached(let days):
                if partner.notifyOnStreak {
                    print("📱 Notifying \(partner.name): \(days) day streak!")
                }
            case .weeklySummary(let donated, let snoozes):
                print("📱 Sending weekly summary to \(partner.name): $\(donated) donated, \(snoozes) snoozes")
            }
        }
    }
    
    enum PartnerNotificationEvent {
        case snoozed(cost: Double)
        case streakReached(days: Int)
        case weeklySummary(donated: Double, snoozes: Int)
    }
}

// MARK: - Preview

#Preview("Social Accountability") {
    SocialAccountabilityView()
        .environmentObject(AlarmManager())
}
