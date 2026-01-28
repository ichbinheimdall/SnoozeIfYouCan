import SwiftUI
import Combine

/// iOS Clock-style alarm edit view
struct AlarmEditView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var soundManager: SoundManager
    @Environment(\.dismiss) private var dismiss
    
    enum Mode {
        case add
        case edit(Alarm)
        
        var title: String {
            switch self {
            case .add: return "Add Alarm"
            case .edit: return "Edit Alarm"
            }
        }
        
        var alarm: Alarm? {
            switch self {
            case .add: return nil
            case .edit(let alarm): return alarm
            }
        }
    }
    
    let mode: Mode
    
    @State private var time = Date()
    @State private var label = ""
    @State private var repeatDays: Set<Weekday> = []
    @State private var selectedSound: AlarmSound = .radar
    @State private var snoozeCost: Double = 1.0
    @State private var showSoundPicker = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        NavigationStack {
            List {
                // Time Picker Section
                Section {
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .onChange(of: time) { _, _ in
                            HapticsManager.shared.selectionChanged()
                        }
                }
                
                // Alarm Options
                Section {
                    // Repeat
                    NavigationLink {
                        RepeatDaysPicker(selectedDays: $repeatDays)
                    } label: {
                        HStack {
                            Text("Repeat")
                            Spacer()
                            Text(repeatDescription)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                    .accessibilityLabel("Repeat: \(repeatDescription)")
                    
                    // Label
                    HStack {
                        Text("Label")
                        TextField("Alarm", text: $label)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    
                    // Sound
                    NavigationLink {
                        AlarmSoundPickerView(selectedSound: $selectedSound)
                    } label: {
                        HStack {
                            Text("Sound")
                            Spacer()
                            Text(selectedSound.name)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                    .accessibilityLabel("Sound: \(selectedSound.name)")
                }
                
                // Snooze Cost Section
                Section {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Text("Base Snooze Cost")
                            Spacer()
                            Text("$\(String(format: "%.2f", snoozeCost))")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(.orange)
                        }
                        
                        Slider(value: $snoozeCost, in: 0.5...10.0, step: 0.5) {
                            Text("Snooze Cost")
                        }
                        .tint(.orange)
                        .onChange(of: snoozeCost) { _, _ in
                            HapticsManager.shared.selectionChanged()
                        }
                        
                        // Cost escalation preview
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Escalation Preview")
                                .font(AppTheme.Typography.caption1)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                            
                            HStack(spacing: AppTheme.Spacing.md) {
                                EscalationBadge(snooze: 1, cost: snoozeCost)
                                EscalationBadge(snooze: 2, cost: snoozeCost * 2)
                                EscalationBadge(snooze: 3, cost: snoozeCost * 3)
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                } header: {
                    Text("Snooze Pricing")
                } footer: {
                    Text("Each snooze costs more. All proceeds go to Darüşşafaka to support children's education.")
                }
                
                // Delete button (only in edit mode)
                if case .edit = mode {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Alarm")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticsManager.shared.lightTap()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAlarm()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadAlarmData()
            }
            .alert("Delete Alarm?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAlarm()
                }
            } message: {
                Text("This alarm will be permanently deleted.")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var repeatDescription: String {
        if repeatDays.isEmpty {
            return "Never"
        } else if repeatDays.count == 7 {
            return "Every day"
        } else if repeatDays == [.saturday, .sunday] {
            return "Weekends"
        } else if repeatDays == [.monday, .tuesday, .wednesday, .thursday, .friday] {
            return "Weekdays"
        } else {
            return repeatDays.sorted(by: { $0.rawValue < $1.rawValue })
                .map { $0.shortName }
                .joined(separator: ", ")
        }
    }
    
    // MARK: - Actions
    
    private func loadAlarmData() {
        if let alarm = mode.alarm {
            time = alarm.time
            label = alarm.label
            repeatDays = alarm.repeatDays
            snoozeCost = alarm.snoozeCost
            // Load sound from alarm if stored
        }
    }
    
    private func saveAlarm() {
        HapticsManager.shared.success()
        
        if var alarm = mode.alarm {
            // Update existing
            alarm.time = time
            alarm.label = label
            alarm.repeatDays = repeatDays
            alarm.snoozeCost = snoozeCost
            alarmManager.updateAlarm(alarm)
        } else {
            // Create new
            let newAlarm = Alarm(
                time: time,
                label: label,
                isEnabled: true,
                repeatDays: repeatDays,
                snoozeCost: snoozeCost
            )
            alarmManager.addAlarm(newAlarm)
        }
        
        dismiss()
    }
    
    private func deleteAlarm() {
        if let alarm = mode.alarm {
            HapticsManager.shared.mediumTap()
            alarmManager.deleteAlarm(alarm)
            dismiss()
        }
    }
}

// MARK: - Escalation Badge

struct EscalationBadge: View {
    let snooze: Int
    let cost: Double
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Text("×\(snooze)")
                .font(AppTheme.Typography.caption2)
                .foregroundStyle(AppTheme.Colors.textTertiary)
            
            Text("$\(String(format: "%.2f", cost))")
                .font(AppTheme.Typography.caption1.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(Color.orange.gradient, in: Capsule())
        }
    }
}

// MARK: - Repeat Days Picker

struct RepeatDaysPicker: View {
    @Binding var selectedDays: Set<Weekday>
    
    var body: some View {
        List {
            // Quick selections
            Section {
                Button {
                    HapticsManager.shared.selectionChanged()
                    selectedDays = Set(Weekday.allCases)
                } label: {
                    HStack {
                        Text("Every Day")
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Spacer()
                        if selectedDays.count == 7 {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                Button {
                    HapticsManager.shared.selectionChanged()
                    selectedDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
                } label: {
                    HStack {
                        Text("Weekdays")
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Spacer()
                        if selectedDays == [.monday, .tuesday, .wednesday, .thursday, .friday] {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                Button {
                    HapticsManager.shared.selectionChanged()
                    selectedDays = [.saturday, .sunday]
                } label: {
                    HStack {
                        Text("Weekends")
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Spacer()
                        if selectedDays == [.saturday, .sunday] {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            
            // Individual days
            Section {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Button {
                        HapticsManager.shared.selectionChanged()
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    } label: {
                        HStack {
                            Text(day.fullName)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Spacer()
                            if selectedDays.contains(day) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Repeat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Alarm Sound Picker View

struct AlarmSoundPickerView: View {
    @Binding var selectedSound: AlarmSound
    @StateObject private var soundManager = SoundManager.shared
    
    var body: some View {
        List {
            Section {
                ForEach(AlarmSound.allCases) { sound in
                    Button {
                        HapticsManager.shared.selectionChanged()
                        selectedSound = sound
                    } label: {
                        HStack {
                            Text(sound.name)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            if selectedSound == sound {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.orange)
                            }
                            
                            // Preview button
                            Button {
                                if soundManager.currentPreviewSound == sound && soundManager.isPreviewPlaying {
                                    soundManager.stopPreview()
                                } else {
                                    soundManager.previewSound(sound)
                                }
                            } label: {
                                Image(systemName: soundManager.currentPreviewSound == sound && soundManager.isPreviewPlaying ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } header: {
                Text("Alarm Sounds")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Sound")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            soundManager.stopPreview()
        }
    }
}

// MARK: - Preview

#Preview("Add Alarm") {
    AlarmEditView(mode: .add)
        .environmentObject(AlarmManager())
        .environmentObject(SoundManager.shared)
}

#Preview("Edit Alarm") {
    AlarmEditView(mode: .edit(Alarm(
        time: Date(),
        label: "Work",
        repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
        snoozeCost: 2.0
    )))
    .environmentObject(AlarmManager())
    .environmentObject(SoundManager.shared)
}
