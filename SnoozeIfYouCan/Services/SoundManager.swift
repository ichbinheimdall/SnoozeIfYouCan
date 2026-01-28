import Foundation
import AVFoundation
import Combine

/// Available alarm sounds
enum AlarmSound: String, CaseIterable, Codable, Identifiable {
    case radar = "Radar"
    case beacon = "Beacon"
    case chimes = "Chimes"
    case circuit = "Circuit"
    case constellation = "Constellation"
    case cosmic = "Cosmic"
    case crystals = "Crystals"
    case hillside = "Hillside"
    case illuminate = "Illuminate"
    case nightOwl = "Night Owl"
    case opening = "Opening"
    case playtime = "Playtime"
    case presto = "Presto"
    case radiate = "Radiate"
    case ripples = "Ripples"
    case sencha = "Sencha"
    case signal = "Signal"
    case silk = "Silk"
    case slowRise = "Slow Rise"
    case stargaze = "Stargaze"
    case summit = "Summit"
    case twinkle = "Twinkle"
    case uplift = "Uplift"
    case waves = "Waves"
    
    var id: String { rawValue }
    var name: String { rawValue }
    
    // System sound file name (these map to iOS system sounds)
    var fileName: String {
        rawValue.lowercased().replacingOccurrences(of: " ", with: "_")
    }
    
    static var `default`: AlarmSound { .radar }
}

/// Alarm volume levels
enum AlarmVolume: Int, CaseIterable, Codable {
    case low = 25
    case medium = 50
    case high = 75
    case maximum = 100
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .maximum: return "Maximum"
        }
    }
    
    var value: Float {
        Float(rawValue) / 100.0
    }
}

/// Manages all audio playback for alarms
@MainActor
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var previewPlayer: AVAudioPlayer?
    
    @Published var isPlaying: Bool = false
    @Published var isPreviewPlaying: Bool = false
    @Published var currentPreviewSound: AlarmSound?
    
    @Published var selectedSound: AlarmSound = .radar {
        didSet {
            UserDefaults.standard.set(selectedSound.rawValue, forKey: "selected_alarm_sound")
        }
    }
    
    @Published var volume: AlarmVolume = .high {
        didSet {
            UserDefaults.standard.set(volume.rawValue, forKey: "alarm_volume")
        }
    }
    
    @Published var vibrationEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(vibrationEnabled, forKey: "vibration_enabled")
        }
    }
    
    @Published var increasingVolume: Bool = true {
        didSet {
            UserDefaults.standard.set(increasingVolume, forKey: "increasing_volume")
        }
    }
    
    private init() {
        loadSettings()
        setupAudioSession()
    }
    
    private func loadSettings() {
        if let soundRaw = UserDefaults.standard.string(forKey: "selected_alarm_sound"),
           let sound = AlarmSound(rawValue: soundRaw) {
            selectedSound = sound
        }
        
        if let volumeRaw = UserDefaults.standard.object(forKey: "alarm_volume") as? Int,
           let vol = AlarmVolume(rawValue: volumeRaw) {
            volume = vol
        }
        
        vibrationEnabled = UserDefaults.standard.object(forKey: "vibration_enabled") as? Bool ?? true
        increasingVolume = UserDefaults.standard.object(forKey: "increasing_volume") as? Bool ?? true
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Alarm Playback
    
    /// Play the alarm sound
    func playAlarm(sound: AlarmSound? = nil) {
        let alarmSound = sound ?? selectedSound
        
        guard let url = createAlarmSoundURL(for: alarmSound) else {
            // Use system sound fallback - only log once
            if !isPlaying {
                print("⚠️ No custom sound found, using system fallback for '\(alarmSound.name)'")
            }
            playSystemSound()
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = increasingVolume ? 0.1 : volume.value
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            
            print("🔊 Playing alarm sound: \(alarmSound.name)")
            
            // Gradually increase volume if enabled
            if increasingVolume {
                startVolumeRamp()
            }
        } catch {
            print("❌ Failed to play alarm: \(error)")
            playSystemSound()
        }
    }
    
    /// Stop the alarm sound
    func stopAlarm() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }
    
    private func startVolumeRamp() {
        // Gradually increase volume over 30 seconds
        let targetVolume = volume.value
        let steps = 30
        let volumeIncrement = targetVolume / Float(steps)
        
        Task {
            for step in 1...steps {
                guard isPlaying else { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                await MainActor.run {
                    audioPlayer?.volume = min(volumeIncrement * Float(step), targetVolume)
                }
            }
        }
    }
    
    // MARK: - Preview Playback
    
    /// Preview a sound
    func previewSound(_ sound: AlarmSound) {
        // Stop any current preview
        stopPreview()
        
        currentPreviewSound = sound
        
        guard let url = createAlarmSoundURL(for: sound) else {
            // Fallback: play a short system sound
            AudioServicesPlaySystemSound(1007)
            
            // Auto-stop after brief delay
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    currentPreviewSound = nil
                    isPreviewPlaying = false
                }
            }
            return
        }
        
        do {
            previewPlayer = try AVAudioPlayer(contentsOf: url)
            previewPlayer?.numberOfLoops = 0 // Play once
            previewPlayer?.volume = volume.value
            previewPlayer?.prepareToPlay()
            previewPlayer?.play()
            isPreviewPlaying = true
            
            // Stop after preview duration
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                await MainActor.run {
                    stopPreview()
                }
            }
        } catch {
            print("❌ Failed to preview sound: \(error)")
        }
    }
    
    /// Stop the preview
    func stopPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
        isPreviewPlaying = false
        currentPreviewSound = nil
    }
    
    // MARK: - Helper Methods
    
    private func createAlarmSoundURL(for sound: AlarmSound) -> URL? {
        // First try to find bundled custom sound files
        if let url = Bundle.main.url(forResource: sound.fileName, withExtension: "m4a") {
            return url
        }
        if let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") {
            return url
        }
        if let url = Bundle.main.url(forResource: sound.fileName, withExtension: "wav") {
            return url
        }
        if let url = Bundle.main.url(forResource: sound.fileName, withExtension: "caf") {
            return url
        }
        
        // Try to use iOS system alarm sounds
        // These are located in /System/Library/Audio/UISounds/ on device
        let systemSoundsPath = "/System/Library/Audio/UISounds"
        let possibleFiles = [
            "\(systemSoundsPath)/Alarm.caf",
            "\(systemSoundsPath)/alarm.caf",
            "\(systemSoundsPath)/Anticipate.caf",
            "\(systemSoundsPath)/Bloom.caf",
            "\(systemSoundsPath)/Calypso.caf",
            "\(systemSoundsPath)/Chimes.caf",
            "\(systemSoundsPath)/Chord.caf",
            "\(systemSoundsPath)/Circles.caf",
            "\(systemSoundsPath)/Complete.caf",
            "\(systemSoundsPath)/Hello.caf",
            "\(systemSoundsPath)/Hillside.caf",
            "\(systemSoundsPath)/Illuminate.caf",
            "\(systemSoundsPath)/Moment.caf",
            "\(systemSoundsPath)/Night Owl.caf",
            "\(systemSoundsPath)/Opening.caf",
            "\(systemSoundsPath)/Playtime.caf",
            "\(systemSoundsPath)/Presto.caf",
            "\(systemSoundsPath)/Radar.caf",
            "\(systemSoundsPath)/Radiate.caf",
            "\(systemSoundsPath)/Ripples.caf",
            "\(systemSoundsPath)/Sencha.caf",
            "\(systemSoundsPath)/Signal.caf",
            "\(systemSoundsPath)/Silk.caf",
            "\(systemSoundsPath)/Slow Rise.caf",
            "\(systemSoundsPath)/Stargaze.caf",
            "\(systemSoundsPath)/Summit.caf",
            "\(systemSoundsPath)/Twinkle.caf",
            "\(systemSoundsPath)/Uplift.caf",
            "\(systemSoundsPath)/Waves.caf"
        ]
        
        // Try each possible system sound file
        for filePath in possibleFiles {
            let url = URL(fileURLWithPath: filePath)
            if FileManager.default.fileExists(atPath: filePath) {
                return url
            }
        }
        
        // No sound file found - will use system sound fallback
        return nil
    }
    
    private func playSystemSound() {
        // Use a longer, more alarm-like system sound
        // System sound IDs:
        // 1005 = SMS received (short beep)
        // 1016 = SMS alert (longer)
        // 1304 = Phone ring (continuous)
        let alarmSoundID: SystemSoundID = 1304 // Phone ring - closest to alarm
        
        AudioServicesPlaySystemSound(alarmSoundID)
        isPlaying = true
        
        // Loop it every 3 seconds
        Task {
            while isPlaying {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if isPlaying {
                    AudioServicesPlaySystemSound(alarmSoundID)
                }
            }
        }
    }
    
    // MARK: - Snooze/Dismiss Sounds
    
    /// Play snooze sound effect
    func playSnoozeSound() {
        AudioServicesPlaySystemSound(1004) // Gentle confirmation sound
    }
    
    /// Play dismiss/success sound
    func playDismissSound() {
        AudioServicesPlaySystemSound(1001) // Success chime
    }
    
    /// Play payment success sound
    func playPaymentSound() {
        AudioServicesPlaySystemSound(1057) // Payment sound
    }
}

// Import for system sounds
import AudioToolbox
