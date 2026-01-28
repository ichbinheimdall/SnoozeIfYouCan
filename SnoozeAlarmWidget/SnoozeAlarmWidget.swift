import WidgetKit
import SwiftUI
import ActivityKit

#if canImport(AlarmKit)
import AlarmKit
#endif

// MARK: - Widget Entry

struct AlarmWidgetEntry: TimelineEntry {
    let date: Date
    let alarm: AlarmInfo?
    
    struct AlarmInfo {
        let id: String
        let label: String
        let time: Date
        let snoozeCost: Double
        let isActive: Bool
    }
}

// MARK: - Timeline Provider

struct AlarmWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> AlarmWidgetEntry {
        AlarmWidgetEntry(
            date: Date(),
            alarm: AlarmWidgetEntry.AlarmInfo(
                id: "placeholder",
                label: "Morning Alarm",
                time: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!,
                snoozeCost: 1.0,
                isActive: true
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AlarmWidgetEntry) -> Void) {
        let entry = AlarmWidgetEntry(
            date: Date(),
            alarm: AlarmWidgetEntry.AlarmInfo(
                id: "snapshot",
                label: "Wake Up!",
                time: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!,
                snoozeCost: 1.0,
                isActive: true
            )
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AlarmWidgetEntry>) -> Void) {
        // In a real app, fetch alarms from shared UserDefaults or App Group
        let currentDate = Date()
        
        // Create entry with next alarm info
        let entry = AlarmWidgetEntry(
            date: currentDate,
            alarm: nil // Will be populated from shared data
        )
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views

struct AlarmWidgetEntryView: View {
    var entry: AlarmWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallAlarmWidget(entry: entry)
        case .systemMedium:
            MediumAlarmWidget(entry: entry)
        case .accessoryCircular:
            CircularAlarmWidget(entry: entry)
        case .accessoryRectangular:
            RectangularAlarmWidget(entry: entry)
        default:
            SmallAlarmWidget(entry: entry)
        }
    }
}

struct SmallAlarmWidget: View {
    let entry: AlarmWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(.orange)
                Text("Next Alarm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let alarm = entry.alarm {
                Text(alarm.time, style: .time)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(alarm.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(.green)
                    Text("$\(String(format: "%.2f", alarm.snoozeCost)) to snooze")
                        .font(.caption2)
                }
            } else {
                Text("No alarms")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumAlarmWidget: View {
    let entry: AlarmWidgetEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Alarm info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "alarm.waves.left.and.right.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text("Snooze If You Can")
                        .font(.headline)
                }
                
                if let alarm = entry.alarm {
                    Text(alarm.time, style: .time)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(alarm.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No alarms set")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Right side - Stats
            if let alarm = entry.alarm {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Snooze Cost")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("$\(String(format: "%.2f", alarm.snoozeCost))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    
                    Text("for charity 💝")
                        .font(.caption)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct CircularAlarmWidget: View {
    let entry: AlarmWidgetEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 2) {
                Image(systemName: "alarm.fill")
                    .font(.title3)
                
                if let alarm = entry.alarm {
                    Text(alarm.time, style: .time)
                        .font(.caption)
                        .fontWeight(.bold)
                } else {
                    Text("--:--")
                        .font(.caption)
                }
            }
        }
    }
}

struct RectangularAlarmWidget: View {
    let entry: AlarmWidgetEntry
    
    var body: some View {
        HStack {
            Image(systemName: "alarm.fill")
                .font(.title2)
            
            VStack(alignment: .leading) {
                if let alarm = entry.alarm {
                    Text(alarm.time, style: .time)
                        .font(.headline)
                    Text("$\(String(format: "%.2f", alarm.snoozeCost)) to snooze")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No alarms")
                        .font(.headline)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Widget Configuration

struct SnoozeAlarmWidget: Widget {
    let kind: String = "SnoozeAlarmWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AlarmWidgetProvider()) { entry in
            AlarmWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Alarm")
        .description("Shows your next alarm and snooze cost.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Live Activity for AlarmKit

@available(iOS 26.0, *)
struct AlarmLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<SnoozeAlarmMetadata>.self) { context in
            // Lock screen / banner UI
            AlarmLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.waves.left.and.right.fill")
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let metadata = context.attributes.metadata {
                        Text("$\(String(format: "%.2f", metadata.snoozeCost))")
                            .foregroundStyle(.orange)
                            .fontWeight(.bold)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.presentation.alert.title)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 20) {
                        Button(intent: StopAlarmIntent()) {
                            Label("Wake Up", systemImage: "sun.max.fill")
                        }
                        .tint(.green)
                        
                        Button(intent: SnoozeAlarmIntent()) {
                            Label("Snooze", systemImage: "bed.double.fill")
                        }
                        .tint(.orange)
                    }
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                if let metadata = context.attributes.metadata {
                    Text("$\(String(format: "%.0f", metadata.snoozeCost))")
                        .foregroundStyle(.orange)
                }
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(.orange)
            }
        }
    }
}

@available(iOS 26.0, *)
struct AlarmLiveActivityView: View {
    let context: ActivityViewContext<AlarmAttributes<SnoozeAlarmMetadata>>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "alarm.waves.left.and.right.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading) {
                    Text(context.attributes.presentation.alert.title)
                        .font(.headline)
                    
                    if let metadata = context.attributes.metadata {
                        Text(metadata.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let metadata = context.attributes.metadata {
                    VStack(alignment: .trailing) {
                        Text("Snooze Cost")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("$\(String(format: "%.2f", metadata.snoozeCost))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            HStack(spacing: 16) {
                Button(intent: StopAlarmIntent()) {
                    Label("I'm Awake!", systemImage: "sun.max.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                
                Button(intent: SnoozeAlarmIntent()) {
                    Label("💰 Snooze", systemImage: "bed.double.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    SnoozeAlarmWidget()
} timeline: {
    AlarmWidgetEntry(
        date: Date(),
        alarm: AlarmWidgetEntry.AlarmInfo(
            id: "preview",
            label: "Morning Alarm",
            time: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!,
            snoozeCost: 1.0,
            isActive: true
        )
    )
}

#Preview(as: .systemMedium) {
    SnoozeAlarmWidget()
} timeline: {
    AlarmWidgetEntry(
        date: Date(),
        alarm: AlarmWidgetEntry.AlarmInfo(
            id: "preview",
            label: "Wake up for work!",
            time: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!,
            snoozeCost: 2.0,
            isActive: true
        )
    )
}
