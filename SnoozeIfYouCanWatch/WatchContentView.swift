import SwiftUI
import WatchConnectivity

struct WatchContentView: View {
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Current Alarm Card
                    if let nextAlarm = viewModel.nextAlarm {
                        NextAlarmCard(alarm: nextAlarm)
                    } else {
                        NoAlarmCard()
                    }
                    
                    // Quick Stats
                    StatsCard(stats: viewModel.stats)
                    
                    // Actions
                    ActionButtonsView(viewModel: viewModel)
                }
                .padding()
            }
            .navigationTitle("Snooze If You Can")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Next Alarm Card

struct NextAlarmCard: View {
    let alarm: WatchAlarmData
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(.orange)
                Text("Next Alarm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Text(alarm.timeString)
                .font(.system(size: 36, weight: .bold, design: .rounded))
            
            if !alarm.label.isEmpty {
                Text(alarm.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                ForEach(alarm.activeDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium))
                        .padding(4)
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color(.darkGray).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - No Alarm Card

struct NoAlarmCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.zzz.fill")
                .font(.title)
                .foregroundStyle(.gray)
            
            Text("No Alarms Set")
                .font(.headline)
            
            Text("Open iPhone app to set alarms")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.darkGray).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stats Card

struct StatsCard: View {
    let stats: WatchStats
    
    var body: some View {
        HStack(spacing: 12) {
            StatItem(
                icon: "flame.fill",
                value: "\(stats.streak)",
                label: "Streak",
                color: .orange
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                icon: "heart.fill",
                value: "$\(String(format: "%.0f", stats.donated))",
                label: "Donated",
                color: .pink
            )
        }
        .padding()
        .background(Color(.darkGray).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Action Buttons

struct ActionButtonsView: View {
    @ObservedObject var viewModel: WatchViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            Button {
                viewModel.refreshData()
            } label: {
                Label("Sync", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            
            if viewModel.hasActiveAlarm {
                Button {
                    viewModel.dismissAlarm()
                } label: {
                    Label("I'm Awake!", systemImage: "sun.max.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
    }
}

// MARK: - Watch View Model

@MainActor
class WatchViewModel: NSObject, ObservableObject {
    @Published var nextAlarm: WatchAlarmData?
    @Published var stats = WatchStats()
    @Published var hasActiveAlarm = false
    
    private var session: WCSession?
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func refreshData() {
        guard let session = session, session.isReachable else { return }
        
        session.sendMessage(["action": "refresh"], replyHandler: { response in
            Task { @MainActor in
                self.handleResponse(response)
            }
        }, errorHandler: { error in
            print("Watch sync error: \(error)")
        })
    }
    
    func dismissAlarm() {
        guard let session = session, session.isReachable else { return }
        
        session.sendMessage(["action": "dismiss"], replyHandler: { _ in
            Task { @MainActor in
                self.hasActiveAlarm = false
            }
        }, errorHandler: nil)
    }
    
    private func handleResponse(_ response: [String: Any]) {
        if let alarmData = response["nextAlarm"] as? [String: Any] {
            nextAlarm = WatchAlarmData(from: alarmData)
        }
        
        if let statsData = response["stats"] as? [String: Any] {
            stats = WatchStats(from: statsData)
        }
    }
}

extension WatchViewModel: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            Task { @MainActor in
                refreshData()
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            if message["alarmActive"] as? Bool == true {
                hasActiveAlarm = true
            }
            handleResponse(message)
        }
    }
}

// MARK: - Data Models

struct WatchAlarmData {
    let timeString: String
    let label: String
    let activeDays: [String]
    
    init(from dict: [String: Any]) {
        self.timeString = dict["time"] as? String ?? "00:00"
        self.label = dict["label"] as? String ?? ""
        self.activeDays = dict["days"] as? [String] ?? []
    }
}

struct WatchStats {
    var streak: Int = 0
    var donated: Double = 0
    
    init() {}
    
    init(from dict: [String: Any]) {
        self.streak = dict["streak"] as? Int ?? 0
        self.donated = dict["donated"] as? Double ?? 0
    }
}

// MARK: - Preview

#Preview {
    WatchContentView()
}
