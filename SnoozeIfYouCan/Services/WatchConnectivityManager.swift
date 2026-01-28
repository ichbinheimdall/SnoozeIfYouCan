import Foundation
import WatchConnectivity
import Combine

/// Manages communication between iPhone and Apple Watch
@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isWatchAppInstalled = false
    @Published var isWatchReachable = false
    
    private var session: WCSession?
    
    private override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else { return }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    // MARK: - Send Data to Watch
    
    func sendAlarmData(alarm: Alarm?, stats: DonationStats) {
        guard let session = session, session.isReachable else { return }
        
        var message: [String: Any] = [:]
        
        if let alarm = alarm {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            
            let daySymbols = Calendar.current.shortWeekdaySymbols
            let activeDays = alarm.repeatDays.map { daySymbols[$0.rawValue - 1] }
            
            message["nextAlarm"] = [
                "time": formatter.string(from: alarm.time),
                "label": alarm.label,
                "days": activeDays
            ]
        }
        
        message["stats"] = [
            "streak": stats.currentStreak,
            "donated": stats.totalDonated
        ]
        
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("Failed to send to watch: \(error)")
        })
    }
    
    func notifyWatchAlarmTriggered(alarm: Alarm) {
        guard let session = session, session.isReachable else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let message: [String: Any] = [
            "alarmActive": true,
            "time": formatter.string(from: alarm.time),
            "label": alarm.label
        ]
        
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
    
    func sendApplicationContext(stats: DonationStats, nextAlarmTime: Date?) {
        guard let session = session, session.activationState == .activated else { return }
        
        var context: [String: Any] = [
            "streak": stats.currentStreak,
            "donated": stats.totalDonated,
            "lastUpdated": Date().timeIntervalSince1970
        ]
        
        if let nextTime = nextAlarmTime {
            context["nextAlarmTime"] = nextTime.timeIntervalSince1970
        }
        
        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Failed to update application context: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if activationState == .activated {
                isWatchAppInstalled = session.isWatchAppInstalled
            }
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session
        session.activate()
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            handleMessage(message, replyHandler: replyHandler)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            handleMessage(message, replyHandler: nil)
        }
    }
    
    @MainActor
    private func handleMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        // Handle actions from watch
        if let action = message["action"] as? String {
            switch action {
            case "refresh":
                // Send current data back
                let response = buildCurrentDataResponse()
                replyHandler?(response)
                
            case "dismiss":
                // Handle alarm dismissal from watch
                NotificationCenter.default.post(name: .watchDismissedAlarm, object: nil)
                replyHandler?(["success": true])
                
            default:
                break
            }
        }
        
        if let alarmAction = message["alarmAction"] as? String {
            switch alarmAction {
            case "dismissed":
                NotificationCenter.default.post(name: .watchDismissedAlarm, object: nil)
            case "snoozed":
                NotificationCenter.default.post(name: .watchSnoozedAlarm, object: nil)
            default:
                break
            }
        }
    }
    
    @MainActor
    private func buildCurrentDataResponse() -> [String: Any] {
        // This would need access to AlarmManager - simplified for now
        return [
            "stats": [
                "streak": 0,
                "donated": 0.0
            ]
        ]
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchDismissedAlarm = Notification.Name("watchDismissedAlarm")
    static let watchSnoozedAlarm = Notification.Name("watchSnoozedAlarm")
}
