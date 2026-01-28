import SwiftUI
import AVFoundation

// MARK: - Sound Picker View

struct SoundPickerView: View {
    @EnvironmentObject var soundManager: SoundManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    private var filteredSounds: [AlarmSound] {
        if searchText.isEmpty {
            return AlarmSound.allCases
        }
        return AlarmSound.allCases.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Volume Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(.orange)
                            Text("Volume")
                                .font(.headline)
                            Spacer()
                            Text(soundManager.volume.displayName)
                                .foregroundStyle(.secondary)
                        }
                        
                        Picker("Volume", selection: $soundManager.volume) {
                            ForEach(AlarmVolume.allCases, id: \.self) { vol in
                                Text(vol.displayName).tag(vol)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)
                    
                    Toggle(isOn: $soundManager.increasingVolume) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text("Increasing Volume")
                                Text("Start quiet, get louder over 30 seconds")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(.orange)
                    
                    Toggle(isOn: $soundManager.vibrationEnabled) {
                        HStack {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .foregroundStyle(.purple)
                            VStack(alignment: .leading) {
                                Text("Vibration")
                                Text("Vibrate along with alarm sound")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(.orange)
                } header: {
                    Text("Sound Settings")
                }
                
                // Sound Selection Section
                Section {
                    ForEach(filteredSounds) { sound in
                        SoundRow(
                            sound: sound,
                            isSelected: soundManager.selectedSound == sound,
                            isPlaying: soundManager.currentPreviewSound == sound && soundManager.isPreviewPlaying
                        ) {
                            soundManager.selectedSound = sound
                        } onPreview: {
                            if soundManager.currentPreviewSound == sound && soundManager.isPreviewPlaying {
                                soundManager.stopPreview()
                            } else {
                                soundManager.previewSound(sound)
                            }
                        }
                    }
                } header: {
                    Text("Alarm Sounds")
                } footer: {
                    Text("Tap the play button to preview a sound")
                }
            }
            .searchable(text: $searchText, prompt: "Search sounds")
            .navigationTitle("Alarm Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        soundManager.stopPreview()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                soundManager.stopPreview()
            }
        }
    }
}

// MARK: - Sound Row

struct SoundRow: View {
    let sound: AlarmSound
    let isSelected: Bool
    let isPlaying: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .orange : .secondary)
                        .font(.title3)
                    
                    Text(sound.name)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            Button(action: onPreview) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isPlaying ? .red : .orange)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
    }
}

// MARK: - Sound Preview Card

struct SoundPreviewCard: View {
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        HStack {
            Image(systemName: "speaker.wave.2.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading) {
                Text(soundManager.selectedSound.name)
                    .font(.headline)
                Text(soundManager.volume.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                if soundManager.isPreviewPlaying {
                    soundManager.stopPreview()
                } else {
                    soundManager.previewSound(soundManager.selectedSound)
                }
            } label: {
                Image(systemName: soundManager.isPreviewPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    SoundPickerView()
        .environmentObject(SoundManager.shared)
}
