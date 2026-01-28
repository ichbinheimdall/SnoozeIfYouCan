import Foundation
import CloudKit
import Combine

// MARK: - CloudKit Sync Manager
/// Handles synchronization of alarm data across devices via iCloud

@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    // MARK: - Published State
    @Published var iCloudStatus: CKAccountStatus = .couldNotDetermine
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: CloudKitError?
    
    // MARK: - Configuration
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let recordZone: CKRecordZone
    
    // Record Types
    private enum RecordType {
        static let alarm = "Alarm"
        static let snoozeRecord = "SnoozeRecord"
        static let userStats = "UserStats"
    }
    
    // Zone name for custom zone (better sync performance)
    private let zoneName = "AlarmZone"
    
    private init() {
        // Use default container or specify your container ID
        container = CKContainer(identifier: "iCloud.com.snoozeifyoucan.app")
        privateDatabase = container.privateCloudDatabase
        recordZone = CKRecordZone(zoneName: zoneName)
        
        Task {
            await checkAccountStatus()
            await createZoneIfNeeded()
        }
    }
    
    // MARK: - Account Status
    
    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            iCloudStatus = status
            
            if status != .available {
                syncError = .iCloudNotAvailable
            }
        } catch {
            iCloudStatus = .couldNotDetermine
            syncError = .unknown(error)
        }
    }
    
    // MARK: - Zone Setup
    
    private func createZoneIfNeeded() async {
        do {
            let _ = try await privateDatabase.modifyRecordZones(
                saving: [recordZone],
                deleting: []
            )
        } catch {
            // Zone might already exist, which is fine
            print("Zone creation: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sync Operations
    
    /// Full sync - downloads all records and uploads local changes
    func performFullSync(with alarmManager: AlarmManager) async {
        guard iCloudStatus == .available else {
            syncError = .iCloudNotAvailable
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            // 1. Fetch all cloud records
            let cloudAlarms = try await fetchAllAlarms()
            
            // 2. Merge with local data
            mergeAlarms(cloud: cloudAlarms, local: alarmManager)
            
            // 3. Upload local changes
            try await uploadAlarms(alarmManager.alarms)
            
            // 4. Upload stats
            try await uploadStats(alarmManager.stats)
            
            lastSyncDate = Date()
        } catch {
            syncError = .syncFailed(error)
        }
        
        isSyncing = false
    }
    
    // MARK: - Fetch Operations
    
    private func fetchAllAlarms() async throws -> [CKRecord] {
        let query = CKQuery(recordType: RecordType.alarm, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        
        let (results, _) = try await privateDatabase.records(
            matching: query,
            inZoneWith: recordZone.zoneID,
            desiredKeys: nil,
            resultsLimit: CKQueryOperation.maximumResults
        )
        
        return results.compactMap { try? $0.1.get() }
    }
    
    // MARK: - Upload Operations
    
    private func uploadAlarms(_ alarms: [Alarm]) async throws {
        let records = alarms.map { alarmToRecord($0) }
        
        let _ = try await privateDatabase.modifyRecords(
            saving: records,
            deleting: [],
            savePolicy: .changedKeys
        )
    }
    
    private func uploadStats(_ stats: DonationStats) async throws {
        let record = statsToRecord(stats)
        
        let _ = try await privateDatabase.modifyRecords(
            saving: [record],
            deleting: [],
            savePolicy: .changedKeys
        )
    }
    
    // MARK: - Record Conversion
    
    private func alarmToRecord(_ alarm: Alarm) -> CKRecord {
        let recordID = CKRecord.ID(recordName: alarm.id.uuidString, zoneID: recordZone.zoneID)
        let record = CKRecord(recordType: RecordType.alarm, recordID: recordID)
        
        record["id"] = alarm.id.uuidString
        record["time"] = alarm.time
        record["label"] = alarm.label
        record["isEnabled"] = alarm.isEnabled ? 1 : 0
        record["snoozeCost"] = alarm.snoozeCost
        record["snoozeCount"] = alarm.snoozeCount
        record["repeatDays"] = alarm.repeatDays.map { $0.rawValue }
        
        return record
    }
    
    private func recordToAlarm(_ record: CKRecord) -> Alarm? {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let time = record["time"] as? Date else {
            return nil
        }
        
        let label = record["label"] as? String ?? ""
        let isEnabled = (record["isEnabled"] as? Int ?? 1) == 1
        let snoozeCost = record["snoozeCost"] as? Double ?? 1.0
        let snoozeCount = record["snoozeCount"] as? Int ?? 0
        let repeatDaysRaw = record["repeatDays"] as? [Int] ?? []
        let repeatDays = Set(repeatDaysRaw.compactMap { Weekday(rawValue: $0) })
        
        return Alarm(
            id: id,
            time: time,
            label: label,
            isEnabled: isEnabled,
            repeatDays: repeatDays,
            snoozeCost: snoozeCost,
            snoozeCount: snoozeCount
        )
    }
    
    private func statsToRecord(_ stats: DonationStats) -> CKRecord {
        let recordID = CKRecord.ID(recordName: "userStats", zoneID: recordZone.zoneID)
        let record = CKRecord(recordType: RecordType.userStats, recordID: recordID)
        
        record["totalDonated"] = stats.totalDonated
        record["totalSnoozes"] = stats.totalSnoozes
        record["currentStreak"] = stats.currentStreak
        record["longestStreak"] = stats.longestStreak
        record["currentWeekAmount"] = stats.currentWeekAmount
        record["currentMonthAmount"] = stats.currentMonthAmount
        
        return record
    }
    
    // MARK: - Merge Logic
    
    private func mergeAlarms(cloud: [CKRecord], local: AlarmManager) {
        let cloudAlarms = cloud.compactMap { recordToAlarm($0) }
        var localDict = Dictionary(uniqueKeysWithValues: local.alarms.map { ($0.id, $0) })
        
        // Merge cloud alarms into local
        for cloudAlarm in cloudAlarms {
            if localDict[cloudAlarm.id] != nil {
                // Conflict resolution: use most recently modified
                // For now, prefer cloud data (could add modification tracking)
                localDict[cloudAlarm.id] = cloudAlarm
            } else {
                // New alarm from cloud
                localDict[cloudAlarm.id] = cloudAlarm
            }
        }
        
        // Update local manager
        local.alarms = Array(localDict.values).sorted { $0.time < $1.time }
    }
    
    // MARK: - Subscription (Push Notifications)
    
    func subscribeToChanges() async {
        let subscription = CKDatabaseSubscription(subscriptionID: "alarm-changes")
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true // Silent push
        subscription.notificationInfo = notificationInfo
        
        do {
            let _ = try await privateDatabase.modifySubscriptions(
                saving: [subscription],
                deleting: []
            )
        } catch {
            print("Failed to create subscription: \(error)")
        }
    }
    
    // MARK: - Delete
    
    func deleteAlarm(_ alarm: Alarm) async throws {
        let recordID = CKRecord.ID(recordName: alarm.id.uuidString, zoneID: recordZone.zoneID)
        
        let _ = try await privateDatabase.modifyRecords(
            saving: [],
            deleting: [recordID]
        )
    }
}

// MARK: - Error Types

enum CloudKitError: LocalizedError {
    case iCloudNotAvailable
    case networkError
    case quotaExceeded
    case syncFailed(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        case .networkError:
            return "Network connection failed. Please check your connection."
        case .quotaExceeded:
            return "iCloud storage is full. Please free up space."
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .unknown(let error):
            return "An error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - Sync Status View

import SwiftUI

struct CloudSyncStatusView: View {
    @StateObject private var cloudKit = CloudKitManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Group {
                switch cloudKit.iCloudStatus {
                case .available:
                    if cloudKit.isSyncing {
                        ProgressView()
                    } else if cloudKit.syncError != nil {
                        Image(systemName: "exclamationmark.icloud.fill")
                            .foregroundStyle(.orange)
                    } else {
                        Image(systemName: "checkmark.icloud.fill")
                            .foregroundStyle(.green)
                    }
                case .noAccount:
                    Image(systemName: "icloud.slash.fill")
                        .foregroundStyle(.red)
                case .restricted, .temporarilyUnavailable:
                    Image(systemName: "icloud.fill")
                        .foregroundStyle(.yellow)
                case .couldNotDetermine:
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(.secondary)
                @unknown default:
                    Image(systemName: "icloud.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.title3)
            
            // Status text
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.subheadline.weight(.medium))
                
                if let date = cloudKit.lastSyncDate {
                    Text("Last synced \(date.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let error = cloudKit.syncError {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
            
            // Manual sync button
            if cloudKit.iCloudStatus == .available && !cloudKit.isSyncing {
                Button {
                    Task {
                        await cloudKit.performFullSync(with: AlarmManager())
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.body)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var statusTitle: String {
        switch cloudKit.iCloudStatus {
        case .available:
            if cloudKit.isSyncing {
                return "Syncing..."
            } else if cloudKit.syncError != nil {
                return "Sync Error"
            }
            return "iCloud Synced"
        case .noAccount:
            return "iCloud Not Signed In"
        case .restricted:
            return "iCloud Restricted"
        case .temporarilyUnavailable:
            return "iCloud Unavailable"
        case .couldNotDetermine:
            return "Checking iCloud..."
        @unknown default:
            return "Unknown Status"
        }
    }
}

// MARK: - Preview

#Preview("Cloud Sync Status") {
    VStack(spacing: 20) {
        CloudSyncStatusView()
    }
    .padding()
}
