import SwiftUI
import UserNotifications

// MARK: - Watch Alarm View (shown when alarm triggers)

struct WatchAlarmView: View {
    @StateObject private var viewModel = WatchAlarmViewModel()
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.orange, .red],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Alarm icon
                Image(systemName: "alarm.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Time
                Text(viewModel.currentTime)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                // Label
                if !viewModel.alarmLabel.isEmpty {
                    Text(viewModel.alarmLabel)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Dismiss button
                Button {
                    viewModel.dismissAlarm()
                } label: {
                    Text("I'm Awake!")
                        .font(.headline)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                // Snooze button (with warning)
                Button {
                    viewModel.snoozeAlarm()
                } label: {
                    VStack(spacing: 4) {
                        Text("Snooze")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text("$\(String(format: "%.2f", viewModel.snoozeAmount))")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .onAppear {
            isAnimating = true
            viewModel.startAlarm()
        }
    }
}

// MARK: - Watch Alarm View Model

@MainActor
class WatchAlarmViewModel: ObservableObject {
    @Published var currentTime: String = ""
    @Published var alarmLabel: String = ""
    @Published var snoozeAmount: Double = 0.99
    
    private var timer: Timer?
    
    func startAlarm() {
        updateTime()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTime()
            }
        }
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.notification)
    }
    
    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        currentTime = formatter.string(from: Date())
    }
    
    func dismissAlarm() {
        timer?.invalidate()
        WKInterfaceDevice.current().play(.success)
        
        // Notify iPhone
        notifyiPhone(action: "dismissed")
    }
    
    func snoozeAlarm() {
        timer?.invalidate()
        WKInterfaceDevice.current().play(.click)
        
        // Notify iPhone about snooze
        notifyiPhone(action: "snoozed")
    }
    
    private func notifyiPhone(action: String) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        
        if session.isReachable {
            session.sendMessage(["alarmAction": action], replyHandler: nil, errorHandler: nil)
        }
    }
}

// Import WatchKit for haptics
import WatchKit
import WatchConnectivity
