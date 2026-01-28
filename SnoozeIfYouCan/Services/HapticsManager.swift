import UIKit
import CoreHaptics
import AVFoundation
import Combine

/// Centralized haptics manager following Apple HIG for haptic feedback
/// Provides consistent, meaningful haptic responses throughout the app
@MainActor
class HapticsManager: ObservableObject {
    static let shared = HapticsManager()
    
    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool = false
    
    @Published var isEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "haptics_enabled")
        }
    }
    
    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: "haptics_enabled")
        if UserDefaults.standard.object(forKey: "haptics_enabled") == nil {
            isEnabled = true // Default to enabled
        }
        setupHapticEngine()
    }
    
    private func setupHapticEngine() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        
        guard supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true
            engine?.isAutoShutdownEnabled = true
            
            // Handle engine reset
            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    print("❌ Failed to restart haptic engine: \(error)")
                }
            }
            
            // Handle engine stopped - engine will be restarted on demand
            engine?.stoppedHandler = { reason in
                // Don't log - this is normal behavior when app backgrounds
            }
            
            try engine?.start()
        } catch {
            print("❌ Failed to create haptic engine: \(error)")
        }
    }
    
    /// Ensure the haptic engine is running before playing patterns
    private func ensureEngineRunning() -> Bool {
        guard supportsHaptics, let engine else { return false }
        
        do {
            try engine.start()
            return true
        } catch {
            // Engine might already be running, which is fine
            return true
        }
    }
    
    // MARK: - Standard Feedback (UIKit)
    
    /// Light tap - for selections, toggles
    func lightTap() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Medium tap - for button presses, confirmations
    func mediumTap() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Heavy tap - for significant actions
    func heavyTap() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Selection changed - for picker wheels, sliders
    func selectionChanged() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    /// Success notification
    func success() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Warning notification
    func warning() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Error notification
    func error() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Custom Haptic Patterns (Core Haptics)
    
    /// Alarm wake-up pattern - escalating intensity
    func alarmPattern() {
        guard isEnabled, supportsHaptics, let engine else {
            // Fallback to basic haptics
            heavyTap()
            return
        }
        
        guard ensureEngineRunning() else {
            heavyTap()
            return
        }
        
        do {
            // Create escalating pattern
            var events: [CHHapticEvent] = []
            
            // Three pulses with increasing intensity
            for i in 0..<3 {
                let intensity = CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: Float(0.5 + Double(i) * 0.2)
                )
                let sharpness = CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: Float(0.3 + Double(i) * 0.2)
                )
                
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: Double(i) * 0.15
                )
                events.append(event)
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("❌ Failed to play alarm haptic: \(error)")
            heavyTap()
        }
    }
    
    /// Snooze confirmation - gentle double tap
    func snoozeConfirm() {
        guard isEnabled, supportsHaptics, let engine else {
            mediumTap()
            return
        }
        
        guard ensureEngineRunning() else {
            mediumTap()
            return
        }
        
        do {
            var events: [CHHapticEvent] = []
            
            // Soft double tap
            for i in 0..<2 {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: Double(i) * 0.1
                )
                events.append(event)
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            mediumTap()
        }
    }
    
    /// Payment success - celebratory pattern
    func paymentSuccess() {
        guard isEnabled, supportsHaptics, let engine else {
            success()
            return
        }
        
        guard ensureEngineRunning() else {
            success()
            return
        }
        
        do {
            var events: [CHHapticEvent] = []
            
            // Rising success pattern
            let intensities: [Float] = [0.4, 0.6, 0.8, 1.0]
            let times: [Double] = [0, 0.08, 0.16, 0.28]
            
            for (index, time) in times.enumerated() {
                let intensity = CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: intensities[index]
                )
                let sharpness = CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: 0.5
                )
                
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: time
                )
                events.append(event)
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            success()
        }
    }
    
    /// Achievement unlocked - special celebration pattern
    func achievementUnlocked() {
        guard isEnabled, supportsHaptics, let engine else {
            success()
            return
        }
        
        guard ensureEngineRunning() else {
            success()
            return
        }
        
        do {
            var events: [CHHapticEvent] = []
            
            // Fanfare pattern
            let pattern1 = [(0.0, 0.6), (0.1, 0.8), (0.25, 1.0), (0.45, 0.7), (0.55, 0.9)]
            
            for (time, intensity) in pattern1 {
                let intensityParam = CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: Float(intensity)
                )
                let sharpness = CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: 0.6
                )
                
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensityParam, sharpness],
                    relativeTime: time
                )
                events.append(event)
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            success()
        }
    }
    
    /// Wake up success - you dismissed without snoozing!
    func wakeUpSuccess() {
        guard isEnabled, supportsHaptics, let engine else {
            success()
            return
        }
        
        guard ensureEngineRunning() else {
            success()
            return
        }
        
        do {
            var events: [CHHapticEvent] = []
            
            // Triumphant double burst
            let bursts: [(time: Double, intensity: Float)] = [
                (0.0, 0.7), (0.05, 0.8), (0.1, 0.9),
                (0.25, 0.8), (0.3, 0.9), (0.35, 1.0)
            ]
            
            for burst in bursts {
                let intensity = CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: burst.intensity
                )
                let sharpness = CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: 0.5
                )
                
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: burst.time
                )
                events.append(event)
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            success()
        }
    }
    
    /// Continuous alarm vibration - for active alarm
    func startAlarmVibration() async {
        guard isEnabled, supportsHaptics, let engine else { return }
        
        guard ensureEngineRunning() else { return }
        
        do {
            // Continuous pulsing pattern
            var events: [CHHapticEvent] = []
            
            for i in 0..<10 {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: Double(i) * 0.2
                )
                events.append(event)
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("❌ Failed to start alarm vibration: \(error)")
        }
    }
}
