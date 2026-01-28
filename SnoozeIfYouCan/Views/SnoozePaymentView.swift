import SwiftUI

struct SnoozePaymentView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var paymentManager: PaymentManager
    @Environment(\.dismiss) private var dismiss
    
    let alarm: Alarm
    @State private var isPurchasing = false
    @State private var showingConfirmation = false
    @State private var purchaseSuccess = false
    
    var snoozeCost: Double {
        alarmManager.getNextSnoozeCost(for: alarm)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Alarm icon
                ZStack {
                    Circle()
                        .fill(.orange.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)
                        .repeatingBounceSymbol(isActive: true)
                }
                
                // Time
                Text(alarm.timeString)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                
                Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Snooze cost card
                VStack(spacing: 16) {
                    Text("Want 5 more minutes?")
                        .font(.headline)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.title)
                            .foregroundStyle(.orange)
                        Text(String(format: "%.2f", snoozeCost))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                    
                    Text("Snooze #\(alarm.snoozeCount + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.2), in: Capsule())
                    
                    // Charity note
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                        Text("Goes to Darüşşafaka")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        showingConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "bed.double.fill")
                            Text("Pay & Snooze")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                    }
                    .disabled(isPurchasing)
                    
                    Button {
                        dismissAlarm()
                    } label: {
                        HStack {
                            Image(systemName: "sun.max.fill")
                            Text("I'm Awake!")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green.gradient, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Confirm Snooze", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Pay $\(String(format: "%.2f", snoozeCost))") {
                    performSnooze()
                }
            } message: {
                Text("You'll be charged $\(String(format: "%.2f", snoozeCost)) to snooze. This donation goes to Darüşşafaka.")
            }
            .alert("Snooze Activated! 😴", isPresented: $purchaseSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("See you in 5 minutes! Your donation helps children get education.")
            }
        }
    }
    
    private func performSnooze() {
        isPurchasing = true
        
        Task {
            // In production, use real StoreKit purchase
            // let success = await paymentManager.purchaseSnooze(amount: snoozeCost)
            
            // For development, simulate purchase
            let success = paymentManager.simulatePurchase(amount: snoozeCost)
            
            if success {
                let _ = alarmManager.snoozeAlarm(alarm)
                purchaseSuccess = true
            }
            
            isPurchasing = false
        }
    }
    
    private func dismissAlarm() {
        alarmManager.dismissAlarm(alarm)
        dismiss()
    }
}

#Preview {
    SnoozePaymentView(alarm: Alarm(
        time: Date(),
        label: "Morning workout",
        snoozeCost: 1.0,
        snoozeCount: 2
    ))
    .environmentObject(AlarmManager())
    .environmentObject(PaymentManager.shared)
}
