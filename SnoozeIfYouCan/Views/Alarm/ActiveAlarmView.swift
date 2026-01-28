import SwiftUI
import Combine

// MARK: - View Conditional Modifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/// Full-screen alarm view that appears when alarm fires
/// Following Apple HIG for urgent, full-screen experiences
struct ActiveAlarmView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var paymentManager: PaymentManager
    
    let alarm: Alarm
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    @State private var showSnoozeConfirm = false
    @State private var isPurchasing = false
    @State private var pulseScale: CGFloat = 1.0
    
    // Current time display
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var snoozeCost: Double {
        alarmManager.getNextSnoozeCost(for: alarm)
    }
    
    private var hasReachedMax: Bool {
        alarmManager.hasReachedMaxSnoozes(alarm)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated gradient background
                animatedBackground
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Pulsing alarm icon
                    alarmIcon
                    
                    Spacer().frame(height: AppTheme.Spacing.xxxl)
                    
                    // Current time
                    timeDisplay
                    
                    // Alarm label
                    if !alarm.label.isEmpty {
                        Text(alarm.label)
                            .font(AppTheme.Typography.title3)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.top, AppTheme.Spacing.md)
                    }
                    
                    Spacer()
                    
                    // Snooze cost card
                    snoozeCostCard
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                    
                    Spacer().frame(height: AppTheme.Spacing.xxxl)
                    
                    // Action buttons
                    actionButtons
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + AppTheme.Spacing.xxl)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
            startAlarmFeedback()
        }
        .onDisappear {
            stopAlarmFeedback()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .alert(L10n.ActiveAlarm.confirmSnooze, isPresented: $showSnoozeConfirm) {
            Button(L10n.Common.cancel, role: .cancel) {
                HapticsManager.shared.lightTap()
            }
            Button(L10n.ActiveAlarm.payAndSnooze(cost: CurrencyFormatter.format(snoozeCost))) {
                performSnooze()
            }
        } message: {
            Text(L10n.ActiveAlarm.snoozeConfirmMessage(cost: CurrencyFormatter.format(snoozeCost)))
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
    
    // MARK: - Animated Background
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var animatedBackground: some View {
        ZStack {
            // Base gradient using brand colors
            AppTheme.Colors.charityGradient
            
            // Animated circles (only when reduce motion is off)
            if !reduceMotion {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .offset(x: isAnimating ? 100 : -100, y: isAnimating ? -100 : 100)
                    .animation(
                        .easeInOut(duration: 4).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .offset(x: isAnimating ? -80 : 80, y: isAnimating ? 150 : -50)
                    .animation(
                        .easeInOut(duration: 3).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
    }
    
    // MARK: - Alarm Icon
    
    private var alarmIcon: some View {
        ZStack {
            // Pulse rings (only when reduce motion is off)
            if !reduceMotion {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.white.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: 150 + CGFloat(index) * 40, height: 150 + CGFloat(index) * 40)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: pulseScale
                        )
                }
            }
            
            // Main icon background
            Circle()
                .fill(.white.opacity(0.2))
                .frame(width: 130, height: 130)
            
            // Bell icon with conditional animation
            Image(systemName: "bell.fill")
                .font(.system(size: 55, weight: .medium))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(reduceMotion ? 0 : (isAnimating ? 15 : -15)))
                .animation(
                    reduceMotion ? .none : .easeInOut(duration: 0.15).repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .repeatingBounceSymbol(isActive: !reduceMotion && isAnimating)
        }
        .accessibilityHidden(true)
    }
    
    // MARK: - Time Display
    
    private var timeDisplay: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(currentTime.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 72, weight: .light, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
            
            Text(currentTime.formatted(date: .complete, time: .omitted))
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Current time: \(currentTime.formatted())"))
    }
    
    // MARK: - Snooze Cost Card
    
    private var snoozeCostCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text(L10n.ActiveAlarm.snoozeCost)
                .font(AppTheme.Typography.caption1)
                .foregroundStyle(.white.opacity(0.7))
                .textCase(.uppercase)
                .tracking(1)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                Text(String(format: "%.2f", snoozeCost))
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            
            if alarm.snoozeCount > 0 {
                Text(String(format: L10n.ActiveAlarm.snoozeNumber, alarm.snoozeCount + 1))
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(.white.opacity(0.2), in: Capsule())
            }
            
            // Charity mention
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "heart.fill")
                    .font(.caption)
                Text(L10n.ActiveAlarm.donatedTo)
                    .font(AppTheme.Typography.caption1)
            }
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(AppTheme.Spacing.xxl)
        .background(.ultraThinMaterial.opacity(0.3), in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Snooze cost: \(String(format: "%.2f", snoozeCost)) dollars, donated to Darüşşafaka"))
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Snooze button
            Button {
                HapticsManager.shared.mediumTap()
                showSnoozeConfirm = true
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "bed.double.fill")
                    Text("\(L10n.ActiveAlarm.snoozeButton) • \(CurrencyFormatter.format(snoozeCost))")
                }
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(.white, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            }
            .disabled(isPurchasing || hasReachedMax)
            .opacity(hasReachedMax ? 0.4 : 1.0)
            .accessibilityLabel(String(localized: "Snooze for \(CurrencyFormatter.format(snoozeCost))"))
            .accessibilityHint(String(localized: "Double tap to snooze and donate"))
            
            if hasReachedMax {
                Text(L10n.ActiveAlarm.forceWakeUp)
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(.white)
                    .padding(.top, AppTheme.Spacing.xs)
            }
            
            // Dismiss button
            Button {
                dismissAlarm()
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "sun.max.fill")
                    Text(L10n.ActiveAlarm.dismissButton)
                }
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(.white.opacity(0.25), in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            }
            .accessibilityLabel(L10n.ActiveAlarm.dismissButton)
            .accessibilityHint(String(localized: "Double tap to dismiss and stop the alarm"))
        }
    }
    
    // MARK: - Actions
    
    private func startAnimations() {
        withAnimation {
            isAnimating = true
            pulseScale = 1.3
        }
    }
    
    private func startAlarmFeedback() {
        // Start sound
        SoundManager.shared.playAlarm()
        
        // Start haptics
        Task {
            await HapticsManager.shared.startAlarmVibration()
        }
    }
    
    private func stopAlarmFeedback() {
        SoundManager.shared.stopAlarm()
    }
    
    private func performSnooze() {
        isPurchasing = true
        
        Task {
            // In production, use real StoreKit
            let success = paymentManager.simulatePurchase(amount: snoozeCost)
            
            if success {
                let _ = alarmManager.snoozeAlarm(alarm)
                
                SoundManager.shared.stopAlarm()
                SoundManager.shared.playSnoozeSound()
                HapticsManager.shared.snoozeConfirm()
                
                onDismiss()
            }
            
            isPurchasing = false
        }
    }
    
    private func dismissAlarm() {
        SoundManager.shared.stopAlarm()
        SoundManager.shared.playDismissSound()
        HapticsManager.shared.wakeUpSuccess()
        
        alarmManager.dismissAlarm(alarm)
        onDismiss()
    }
}

// MARK: - Preview

#Preview("Active Alarm") {
    ActiveAlarmView(
        alarm: Alarm(
            time: Date(),
            label: "Wake up for work!",
            snoozeCost: 1.0,
            snoozeCount: 2
        ),
        onDismiss: {}
    )
    .environmentObject(AlarmManager())
    .environmentObject(PaymentManager.shared)
}
