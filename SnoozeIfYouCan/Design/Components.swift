import SwiftUI

// MARK: - Reusable UI Components
// Following Apple HIG for consistent, accessible design

// MARK: - Time Picker (iOS Clock-style)

struct AlarmTimePicker: View {
    @Binding var time: Date
    
    var body: some View {
        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Select alarm time")
    }
}

// MARK: - Alarm Toggle (iOS-style)

struct AlarmToggle: View {
    @Binding var isOn: Bool
    let label: String
    
    var body: some View {
        Toggle(label, isOn: $isOn)
            .tint(.orange)
            .accessibilityHint(isOn ? "Alarm is enabled" : "Alarm is disabled")
    }
}

// MARK: - Weekday Selector (iOS Alarm style)

struct WeekdaySelector: View {
    @Binding var selectedDays: Set<Weekday>
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(Weekday.allCases, id: \.self) { day in
                WeekdayButton(
                    day: day,
                    isSelected: selectedDays.contains(day),
                    action: { toggleDay(day) }
                )
            }
        }
    }
    
    private func toggleDay(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

struct WeekdayButton: View {
    let day: Weekday
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day.initial)
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .frame(width: 40, height: 40)
                .foregroundStyle(isSelected ? .white : AppTheme.Colors.textSecondary)
                .background(
                    Circle()
                        .fill(isSelected ? Color.orange : Color.clear)
                )
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? Color.clear : AppTheme.Colors.separator, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.fullName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Cost Display Badge

struct CostBadge: View {
    let amount: Double
    let style: CostBadgeStyle
    
    enum CostBadgeStyle {
        case small, medium, large
        
        var font: Font {
            switch self {
            case .small: return .caption.bold()
            case .medium: return .subheadline.bold()
            case .large: return .title2.bold()
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 12
            }
        }
    }
    
    var body: some View {
        Text("$\(String(format: "%.2f", amount))")
            .font(style.font)
            .foregroundStyle(.white)
            .padding(.horizontal, style.padding)
            .padding(.vertical, style.padding / 2)
            .background(Color.orange.gradient, in: Capsule())
            .accessibilityLabel("\(String(format: "%.2f", amount)) dollars")
    }
}

// MARK: - Stat Card (for dashboard)

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            
            Text(value)
                .font(AppTheme.Typography.title2)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            Text(title)
                .font(AppTheme.Typography.caption1)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.lg)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool
    var progress: Double = 0
    var animate: Bool = false
    var animationDelay: Double = 0
    
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.color.gradient : Color.gray.opacity(0.3).gradient)
                    .frame(width: 60, height: 60)
                
                // Progress ring (for locked)
                if !isUnlocked && progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(achievement.color.opacity(0.5), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                }
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundStyle(isUnlocked ? .white : .gray)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
            }
            
            Text(achievement.title)
                .font(AppTheme.Typography.caption1)
                .foregroundStyle(isUnlocked ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
        .opacity(isUnlocked ? 1.0 : 0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.title), \(isUnlocked ? "unlocked" : "locked")")
        .onAppear {
            if animate {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(animationDelay)) {
                    appeared = true
                }
            } else {
                appeared = true
            }
        }
    }
}

// MARK: - Streak Display

struct StreakDisplay: View {
    let currentStreak: Int
    let bestStreak: Int
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxl) {
            VStack(spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(currentStreak)")
                        .font(AppTheme.Typography.title1)
                }
                Text("Current Streak")
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("\(bestStreak)")
                        .font(AppTheme.Typography.title1)
                }
                Text("Best Streak")
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current streak: \(currentStreak) days. Best streak: \(bestStreak) days.")
    }
}

// MARK: - Sound Picker Row

struct SoundPickerRow: View {
    let sound: AlarmSound
    let isSelected: Bool
    let isPlaying: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    Text(sound.name)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.orange)
                            .fontWeight(.semibold)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Button(action: onPreview) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? "Stop preview" : "Preview sound")
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sound.name)\(isSelected ? ", selected" : "")")
        .accessibilityHint("Double tap to select, triple tap to preview")
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundStyle(.orange.gradient)
                .accessibilityHidden(true)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(AppTheme.Typography.title2)
                
                Text(message)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xxxl)
            }
            
            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, AppTheme.Spacing.huge)
                .padding(.top, AppTheme.Spacing.md)
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundPrimary)
    }
}

// MARK: - Symbol Effects (Compatibility)

extension View {
    /// Applies the bounce symbol effect with repeating animation
    @ViewBuilder
    func repeatingBounceSymbol(isActive: Bool) -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.bounce, options: .repeating, isActive: isActive)
        } else {
            self
        }
    }
}

// MARK: - Weekday Extension

extension Weekday {
    var initial: String {
        String(shortName.prefix(1))
    }
}

// MARK: - Previews

private struct ComponentsPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StreakDisplay(currentStreak: 7, bestStreak: 14)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    StatCard(title: "Total Donated", value: "$42.50", icon: "heart.fill", color: .pink)
                    StatCard(title: "Snoozes", value: "23", icon: "bed.double.fill", color: .orange)
                }
                
                EmptyStateView(
                    icon: "alarm.waves.left.and.right",
                    title: "No Alarms Yet",
                    message: "Add your first alarm to start your wake-up journey",
                    actionTitle: "Add Alarm",
                    action: {}
                )
            }
            .padding()
        }
    }
}

#Preview("Components") {
    ComponentsPreview()
}
