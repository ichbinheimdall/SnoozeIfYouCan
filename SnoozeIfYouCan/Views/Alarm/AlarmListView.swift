import SwiftUI

/// iOS Clock-style alarm list view
struct AlarmListView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var showingAddAlarm = false
    @State private var alarmToEdit: Alarm?
    @State private var showingActiveAlarm = false
    @State private var activeAlarm: Alarm?
    
    /// Check if AlarmKit is available (iOS 26+)
    private var alarmKitAvailable: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if alarmManager.alarms.isEmpty {
                    emptyStateView
                } else {
                    alarmList
                }
            }
            .navigationTitle("Alarms")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        HapticsManager.shared.lightTap()
                        showingAddAlarm = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .accessibilityLabel("Add new alarm")
                }
                
                // Edit mode for reordering (future feature)
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AlarmEditView(mode: .add)
            }
            .sheet(item: $alarmToEdit) { alarm in
                AlarmEditView(mode: .edit(alarm))
            }
            .fullScreenCover(isPresented: $showingActiveAlarm) {
                if let alarm = activeAlarm {
                    ActiveAlarmView(alarm: alarm) {
                        showingActiveAlarm = false
                        activeAlarm = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "alarm.waves.left.and.right",
            title: "No Alarms",
            message: "Tap + to add your first alarm.\nSnoozing costs money—but it goes to a great cause!",
            actionTitle: "Add Alarm",
            action: {
                HapticsManager.shared.lightTap()
                showingAddAlarm = true
            }
        )
    }
    
    // MARK: - Alarm List
    
    private var alarmList: some View {
        List {
            // Active alarms section
            if !activeAlarms.isEmpty {
                Section {
                    ForEach(activeAlarms) { alarm in
                        AlarmRow(alarm: alarm, onToggle: {
                            toggleAlarm(alarm)
                        })
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticsManager.shared.lightTap()
                            alarmToEdit = alarm
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteAlarm(alarm)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                // Test alarm
                                activeAlarm = alarm
                                showingActiveAlarm = true
                            } label: {
                                Label("Test", systemImage: "play.fill")
                            }
                            .tint(.blue)
                        }
                    }
                } header: {
                    Text("Active")
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            
            // Inactive alarms section
            if !inactiveAlarms.isEmpty {
                Section {
                    ForEach(inactiveAlarms) { alarm in
                        AlarmRow(alarm: alarm, onToggle: {
                            toggleAlarm(alarm)
                        })
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticsManager.shared.lightTap()
                            alarmToEdit = alarm
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteAlarm(alarm)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Inactive")
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Computed Properties
    
    private var activeAlarms: [Alarm] {
        alarmManager.alarms.filter { $0.isEnabled }.sorted { $0.time < $1.time }
    }
    
    private var inactiveAlarms: [Alarm] {
        alarmManager.alarms.filter { !$0.isEnabled }.sorted { $0.time < $1.time }
    }
    
    // MARK: - Actions
    
    private func toggleAlarm(_ alarm: Alarm) {
        HapticsManager.shared.selectionChanged()
        alarmManager.toggleAlarm(alarm)
    }
    
    private func deleteAlarm(_ alarm: Alarm) {
        HapticsManager.shared.mediumTap()
        withAnimation {
            alarmManager.deleteAlarm(alarm)
        }
    }
}

// MARK: - Alarm Row

struct AlarmRow: View {
    let alarm: Alarm
    let onToggle: () -> Void
    
    @EnvironmentObject var alarmManager: AlarmManager
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Time and details
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                // Time display (iOS style)
                Text(alarm.timeString)
                    .font(AppTheme.Typography.timeDisplaySmall)
                    .foregroundStyle(alarm.isEnabled ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                
                // Label and repeat
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(alarm.isEnabled ? AppTheme.Colors.textSecondary : AppTheme.Colors.textTertiary)
                    
                    if !alarm.repeatDays.isEmpty {
                        Text("•")
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                        Text(alarm.repeatDescription)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(alarm.isEnabled ? AppTheme.Colors.textSecondary : AppTheme.Colors.textTertiary)
                    }
                }
                
                // Snooze cost indicator
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(alarm.isEnabled ? .orange : .gray)
                        .font(.caption)
                    Text("$\(String(format: "%.2f", alarmManager.getNextSnoozeCost(for: alarm))) to snooze")
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(alarm.isEnabled ? .orange : AppTheme.Colors.textTertiary)
                }
                .padding(.top, AppTheme.Spacing.xxs)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(.orange)
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(alarm.timeString), \(alarm.label.isEmpty ? "Alarm" : alarm.label), \(alarm.repeatDescription), snooze cost \(String(format: "%.2f", alarmManager.getNextSnoozeCost(for: alarm))) dollars")
        .accessibilityValue(alarm.isEnabled ? "On" : "Off")
        .accessibilityHint("Double tap to edit, swipe to delete or test")
    }
}

// MARK: - Preview

#Preview("Alarm List") {
    AlarmListView()
        .environmentObject(AlarmManager())
        .environmentObject(PaymentManager.shared)
}
