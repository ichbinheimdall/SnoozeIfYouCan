import SwiftUI

/// Updated main app entry point with onboarding, proper initialization
@main
struct SnoozeIfYouCanApp: App {
    // State objects for dependency injection
    @StateObject private var alarmManager = AlarmManager()
    @StateObject private var paymentManager = PaymentManager.shared
    @StateObject private var soundManager = SoundManager.shared
    @StateObject private var hapticsManager = HapticsManager.shared
    
    // Track app lifecycle
    @Environment(\.scenePhase) private var scenePhase
    
    // Onboarding state
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // For handling notification responses
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(alarmManager)
            .environmentObject(paymentManager)
            .environmentObject(soundManager)
            .environmentObject(hapticsManager)
            .onAppear {
                setupApp()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
            }
        }
    }
    
    private func setupApp() {
        // Setup notification categories
        NotificationManager.shared.setupNotificationCategories()
        
        // Request permissions
        if hasCompletedOnboarding {
            Task {
                // Request AlarmKit or notification authorization
                let granted = await AlarmServiceHelper.requestAuthorization()
                
                // Always request critical alert permission as fallback/backup
                NotificationManager.shared.requestPermission(allowCritical: true)
                
                if granted {
                    print("✅ Alarm authorization granted")
                } else {
                    print("⚠️ Alarm authorization denied")
                }
            }
        }
    }
    
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active - check for any pending alarm notifications
            checkForPendingAlarms()
        case .background:
            // App went to background
            break
        case .inactive:
            // App is inactive (transitioning)
            break
        @unknown default:
            break
        }
    }
    
    private func checkForPendingAlarms() {
        // Check if there are any delivered notifications that should trigger the alarm
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            for notification in notifications {
                if notification.request.content.categoryIdentifier == "ALARM_CATEGORY" {
                    // Trigger the alarm UI
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .alarmDidFire,
                            object: nil,
                            userInfo: notification.request.content.userInfo
                        )
                    }
                }
            }
        }
    }
}

// MARK: - App Delegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground (for alarm)
        completionHandler([.banner, .sound, .badge])
        
        // Post notification for app to handle
        NotificationCenter.default.post(
            name: .alarmDidFire,
            object: nil,
            userInfo: notification.request.content.userInfo
        )
    }
    
    // Handle notification action (snooze/dismiss)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "SNOOZE_ACTION":
            NotificationCenter.default.post(
                name: .snoozeRequested,
                object: nil,
                userInfo: userInfo
            )
            
        case "DISMISS_ACTION":
            NotificationCenter.default.post(
                name: .dismissRequested,
                object: nil,
                userInfo: userInfo
            )
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification - launch the full alarm UI
            NotificationCenter.default.post(
                name: .alarmDidFire,
                object: nil,
                userInfo: userInfo
            )
            
        default:
            break
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let alarmDidFire = Notification.Name("alarmDidFire")
    static let snoozeRequested = Notification.Name("snoozeRequested")
    static let dismissRequested = Notification.Name("dismissRequested")
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var soundManager: SoundManager
    @EnvironmentObject var hapticsManager: HapticsManager
    @State private var selectedTab = 0
    @State private var showingActiveAlarm = false
    @State private var activeAlarm: Alarm?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AlarmListView()
                .tabItem {
                    Label("Alarms", systemImage: "alarm.fill")
                }
                .tag(0)
            
            ImpactDashboardView()
                .tabItem {
                    Label("Impact", systemImage: "heart.fill")
                }
                .tag(1)
            
            SocialAccountabilityView()
                .tabItem {
                    Label("Social", systemImage: "person.2.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.orange)
        .onReceive(NotificationCenter.default.publisher(for: .alarmDidFire)) { notification in
            handleAlarmFired(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .snoozeRequested)) { notification in
            handleSnoozeRequested(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissRequested)) { notification in
            handleDismissRequested(notification)
        }
        .fullScreenCover(isPresented: $showingActiveAlarm) {
            if let alarm = activeAlarm {
                ActiveAlarmView(alarm: alarm) {
                    soundManager.stopAlarm()
                    showingActiveAlarm = false
                    activeAlarm = nil
                }
            }
        }
    }
    
    private func handleAlarmFired(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let alarmIdString = userInfo["alarmId"] as? String,
              let alarmId = UUID(uuidString: alarmIdString),
              let alarm = alarmManager.alarms.first(where: { $0.id == alarmId }) else {
            return
        }
        
        activeAlarm = alarm
        showingActiveAlarm = true
        soundManager.playAlarm()
        hapticsManager.mediumTap()
    }

    private func handleSnoozeRequested(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let alarmIdString = userInfo["alarmId"] as? String,
              let alarmId = UUID(uuidString: alarmIdString),
              let alarm = alarmManager.alarms.first(where: { $0.id == alarmId }) else {
            return
        }
        _ = alarmManager.snoozeAlarm(alarm)
        soundManager.stopAlarm()
        showingActiveAlarm = false
        activeAlarm = nil
    }

    private func handleDismissRequested(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let alarmIdString = userInfo["alarmId"] as? String,
              let alarmId = UUID(uuidString: alarmIdString),
              let alarm = alarmManager.alarms.first(where: { $0.id == alarmId }) else {
            return
        }
        alarmManager.dismissAlarm(alarm)
        soundManager.stopAlarm()
        showingActiveAlarm = false
        activeAlarm = nil
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(AlarmManager())
        .environmentObject(PaymentManager.shared)
        .environmentObject(SoundManager.shared)
        .environmentObject(HapticsManager.shared)
}
