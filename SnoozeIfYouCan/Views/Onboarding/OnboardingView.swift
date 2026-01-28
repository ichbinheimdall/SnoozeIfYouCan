import SwiftUI
import Combine
import UserNotifications

/// Onboarding flow following Apple HIG
/// - Progressive disclosure
/// - Clear value proposition
/// - Permission requests at appropriate moments
struct OnboardingView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var currentPage = 0
    @State private var showPermissionRequest = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "alarm.waves.left.and.right",
            title: "Wake Up With Purpose",
            subtitle: "The alarm that makes snoozing cost you—but for a good cause.",
            color: .orange
        ),
        OnboardingPage(
            image: "dollarsign.circle.fill",
            title: "Snooze = Donate",
            subtitle: "Every time you hit snooze, you'll donate to Darüşşafaka, helping children get the education they deserve.",
            color: .pink
        ),
        OnboardingPage(
            image: "chart.line.uptrend.xyaxis",
            title: "Escalating Stakes",
            subtitle: "First snooze: $1. Second: $2. Third: $3. The longer you sleep, the more you give.",
            color: .purple
        ),
        OnboardingPage(
            image: "flame.fill",
            title: "Build Your Streak",
            subtitle: "Wake up without snoozing to build your streak. Earn achievements and track your impact.",
            color: .orange
        ),
        OnboardingPage(
            image: "person.2.fill",
            title: "Stay Accountable",
            subtitle: "Add accountability partners who get notified when you snooze. No more excuses!",
            color: .blue
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    pages[currentPage].color.opacity(0.15),
                    AppTheme.Colors.backgroundPrimary
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation {
                                currentPage = pages.count - 1
                            }
                        }
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .padding()
                    }
                }
                .frame(height: 50)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AppTheme.Animation.smooth, value: currentPage)
                
                // Page indicator & buttons
                VStack(spacing: AppTheme.Spacing.xxl) {
                    // Custom page indicator
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(pages.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.orange : Color.gray.opacity(0.3))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(AppTheme.Animation.spring, value: currentPage)
                        }
                    }
                    
                    // Action button
                    Button {
                        handleContinue()
                    } label: {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                }
                .padding(.bottom, AppTheme.Spacing.huge)
            }
        }
        .sheet(isPresented: $showPermissionRequest) {
            PermissionRequestView(onComplete: completeOnboarding)
        }
    }
    
    private func handleContinue() {
        HapticsManager.shared.lightTap()
        
        if currentPage < pages.count - 1 {
            withAnimation(AppTheme.Animation.smooth) {
                currentPage += 1
            }
        } else {
            showPermissionRequest = true
        }
    }
    
    private func completeOnboarding() {
        HapticsManager.shared.success()
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let subtitle: String
    let color: Color
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxxl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 180, height: 180)
                
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Image(systemName: page.image)
                    .font(.system(size: 64))
                    .foregroundStyle(page.color.gradient)
                    .symbolEffect(.pulse, options: .repeating, isActive: isAnimating)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0)
            
            // Text content
            VStack(spacing: AppTheme.Spacing.md) {
                Text(page.title)
                    .font(AppTheme.Typography.title1)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xxl)
            }
            .offset(y: isAnimating ? 0 : 20)
            .opacity(isAnimating ? 1.0 : 0)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(AppTheme.Animation.smooth.delay(0.1)) {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.subtitle)")
    }
}

// MARK: - Permission Request View

struct PermissionRequestView: View {
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void
    
    @State private var notificationsGranted = false
    @State private var alarmKitGranted = false
    @State private var showingNotificationError = false
    
    /// Check if running on iOS 26+ where AlarmKit is available
    private var alarmKitAvailable: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xxxl) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: alarmKitAvailable ? "alarm.waves.left.and.right.fill" : "bell.badge.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange.gradient)
                        .repeatingBounceSymbol(isActive: true)
                }
                
                VStack(spacing: AppTheme.Spacing.md) {
                    Text(alarmKitAvailable ? "Enable Alarms" : "Enable Notifications")
                        .font(AppTheme.Typography.title1)
                    
                    Text(alarmKitAvailable 
                         ? "Allow alarms to wake you up with prominent alerts that override Do Not Disturb and Focus modes."
                         : "Notifications are required for alarms to work. We'll only send you alarm alerts—no spam, ever.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                }
                
                // Permission status
                VStack(spacing: AppTheme.Spacing.sm) {
                    if alarmKitGranted {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Alarm access enabled!")
                                .foregroundStyle(.green)
                        }
                        .font(AppTheme.Typography.headline)
                    }
                    
                    if notificationsGranted {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Notifications enabled!")
                                .foregroundStyle(.green)
                        }
                        .font(AppTheme.Typography.headline)
                    }
                }
                
                Spacer()
                
                VStack(spacing: AppTheme.Spacing.md) {
                    // AlarmKit permission button (iOS 26+)
                    if alarmKitAvailable && !alarmKitGranted {
                        Button {
                            requestAlarmKitPermission()
                        } label: {
                            Label("Enable Alarms", systemImage: "alarm.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    
                    // Notification permission button (fallback or additional)
                    if !notificationsGranted && (!alarmKitAvailable || alarmKitGranted) {
                        if alarmKitGranted {
                            Button {
                                requestNotificationPermission()
                            } label: {
                                Label("Enable Notifications", systemImage: "bell.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        } else {
                            Button {
                                requestNotificationPermission()
                            } label: {
                                Label("Enable Notifications", systemImage: "bell.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    
                    // Continue button
                    if (alarmKitAvailable && alarmKitGranted) || (!alarmKitAvailable && notificationsGranted) {
                        Button {
                            dismiss()
                            onComplete()
                        } label: {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button {
                            dismiss()
                            onComplete()
                        } label: {
                            Text("Maybe Later")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xxl)
                .padding(.bottom, AppTheme.Spacing.huge)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                        onComplete()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Notifications Required", isPresented: $showingNotificationError) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable notifications in Settings to use alarms.")
            }
            .onAppear {
                checkInitialPermissionState()
            }
        }
    }
    
    private func checkInitialPermissionState() {
        // Check notification permission state
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsGranted = settings.authorizationStatus == .authorized
            }
        }
        
        // Check AlarmKit permission state (iOS 26+)
        if #available(iOS 26.0, *) {
            Task { @MainActor in
                let state = AlarmKitService.shared.isAuthorized
                alarmKitGranted = state
            }
        }
    }
    
    private func requestAlarmKitPermission() {
        print("🔘 Enable Alarms button tapped!")
        Task { @MainActor in
            print("🔐 Requesting AlarmKit authorization...")
            let granted = await AlarmServiceHelper.requestAuthorization()
            print("🔐 AlarmKit authorization result: \(granted)")
            if granted {
                print("✅ AlarmKit permission granted!")
                HapticsManager.shared.success()
                withAnimation {
                    alarmKitGranted = true
                }
            } else {
                print("❌ AlarmKit permission denied or failed")
                HapticsManager.shared.error()
                // Show an alert to guide user to settings if permission was denied
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    HapticsManager.shared.success()
                    withAnimation {
                        notificationsGranted = true
                    }
                    // Setup notification categories
                    NotificationManager.shared.setupNotificationCategories()
                } else {
                    HapticsManager.shared.error()
                    showingNotificationError = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    OnboardingView()
        .environmentObject(AlarmManager())
}

#Preview("Permission Request") {
    PermissionRequestView(onComplete: {})
}
