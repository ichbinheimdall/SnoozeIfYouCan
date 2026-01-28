import SwiftUI

struct AlarmRowView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    let alarm: Alarm
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(.system(size: 42, weight: .light, design: .rounded))
                    .foregroundStyle(alarm.isEnabled ? .primary : .secondary)
                
                HStack(spacing: 8) {
                    Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(alarm.repeatDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Snooze cost indicator
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Snooze: $\(String(format: "%.2f", alarmManager.getNextSnoozeCost(for: alarm)))")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in alarmManager.toggleAlarm(alarm) }
            ))
            .labelsHidden()
            .tint(.orange)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        AlarmRowView(alarm: Alarm(
            time: Date(),
            label: "Wake up for work",
            isEnabled: true,
            repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            snoozeCost: 1.0
        ))
        
        AlarmRowView(alarm: Alarm(
            time: Date(),
            label: "Weekend gym",
            isEnabled: false,
            repeatDays: [.saturday, .sunday],
            snoozeCost: 2.0
        ))
    }
    .environmentObject(AlarmManager())
}
