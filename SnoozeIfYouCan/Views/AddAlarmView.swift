import SwiftUI

struct AddAlarmView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @Environment(\.dismiss) private var dismiss
    
    var alarmToEdit: Alarm?
    
    @State private var time = Date()
    @State private var label = ""
    @State private var repeatDays: Set<Weekday> = []
    @State private var snoozeCost: Double = 1.0
    
    private var isEditing: Bool { alarmToEdit != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                // Time Picker
                Section {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
                
                // Label
                Section {
                    TextField("Label (e.g., Wake up for work)", text: $label)
                } header: {
                    Text("Label")
                }
                
                // Repeat Days
                Section {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        Button {
                            toggleDay(day)
                        } label: {
                            HStack {
                                Text(day.fullName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if repeatDays.contains(day) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Repeat")
                } footer: {
                    Text("Leave empty for a one-time alarm")
                }
                
                // Snooze Cost
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Base cost:")
                            Spacer()
                            Text("$\(String(format: "%.2f", snoozeCost))")
                                .font(.headline)
                                .foregroundStyle(.orange)
                        }
                        
                        Slider(value: $snoozeCost, in: 0.5...10, step: 0.5) {
                            Text("Snooze Cost")
                        }
                        .tint(.orange)
                        
                        // Cost escalation preview
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cost escalation:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 12) {
                                CostPreviewBadge(snooze: 1, cost: snoozeCost)
                                CostPreviewBadge(snooze: 2, cost: snoozeCost * 2)
                                CostPreviewBadge(snooze: 3, cost: snoozeCost * 3)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Snooze Cost")
                } footer: {
                    Text("Each snooze costs more! All proceeds go to Darüşşafaka.")
                }
            }
            .navigationTitle(isEditing ? "Edit Alarm" : "New Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAlarm()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let alarm = alarmToEdit {
                    time = alarm.time
                    label = alarm.label
                    repeatDays = alarm.repeatDays
                    snoozeCost = alarm.snoozeCost
                }
            }
        }
    }
    
    private func toggleDay(_ day: Weekday) {
        if repeatDays.contains(day) {
            repeatDays.remove(day)
        } else {
            repeatDays.insert(day)
        }
    }
    
    private func saveAlarm() {
        if var alarm = alarmToEdit {
            alarm.time = time
            alarm.label = label
            alarm.repeatDays = repeatDays
            alarm.snoozeCost = snoozeCost
            alarmManager.updateAlarm(alarm)
        } else {
            let newAlarm = Alarm(
                time: time,
                label: label,
                isEnabled: true,
                repeatDays: repeatDays,
                snoozeCost: snoozeCost
            )
            alarmManager.addAlarm(newAlarm)
        }
    }
}

struct CostPreviewBadge: View {
    let snooze: Int
    let cost: Double
    
    var body: some View {
        VStack(spacing: 2) {
            Text("#\(snooze)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("$\(String(format: "%.2f", cost))")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange.gradient, in: Capsule())
        }
    }
}

#Preview {
    AddAlarmView()
        .environmentObject(AlarmManager())
}
