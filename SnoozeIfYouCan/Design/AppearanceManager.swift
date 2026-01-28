import SwiftUI
import Combine

// MARK: - Dark Mode Configuration

/// App-wide appearance manager
@MainActor
class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()
    
    @Published var preferredColorScheme: ColorScheme? {
        didSet {
            savePreference()
            updateAppearance()
        }
    }
    
    @Published var useTrueDarkMode: Bool = true {
        didSet {
            UserDefaults.standard.set(useTrueDarkMode, forKey: "useTrueDarkMode")
        }
    }
    
    private let colorSchemeKey = "preferredColorScheme"
    
    private init() {
        loadPreferences()
    }
    
    private func loadPreferences() {
        if let savedScheme = UserDefaults.standard.string(forKey: colorSchemeKey) {
            switch savedScheme {
            case "light":
                preferredColorScheme = .light
            case "dark":
                preferredColorScheme = .dark
            default:
                preferredColorScheme = nil // System
            }
        }
        
        useTrueDarkMode = UserDefaults.standard.object(forKey: "useTrueDarkMode") as? Bool ?? true
    }
    
    private func savePreference() {
        let value: String?
        switch preferredColorScheme {
        case .light:
            value = "light"
        case .dark:
            value = "dark"
        case .none:
            value = nil
        @unknown default:
            value = nil
        }
        
        if let value {
            UserDefaults.standard.set(value, forKey: colorSchemeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: colorSchemeKey)
        }
    }
    
    private func updateAppearance() {
        // Force UI update if needed
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                switch preferredColorScheme {
                case .light:
                    window.overrideUserInterfaceStyle = .light
                case .dark:
                    window.overrideUserInterfaceStyle = .dark
                case .none:
                    window.overrideUserInterfaceStyle = .unspecified
                @unknown default:
                    window.overrideUserInterfaceStyle = .unspecified
                }
            }
        }
    }
}

// MARK: - Color Scheme Preference

enum ColorSchemePreference: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Dark Mode Adaptive Colors

extension AppTheme.Colors {
    /// Card background that adapts to dark mode
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.12) 
            : Color(.secondarySystemBackground)
    }
    
    /// Elevated surface color
    static func elevatedSurface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.18) 
            : Color.white
    }
    
    /// Text color that ensures readability
    static func adaptiveText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }
    
    /// Primary color with brightness adjustment for dark mode
    static func adaptivePrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(red: 1.0, green: 0.55, blue: 0.1) // Brighter orange for dark
            : primary
    }
}

// MARK: - Dark Mode View Modifier

struct DarkModeAdaptive: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, colorScheme)
    }
}

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
    @StateObject private var appearanceManager = AppearanceManager.shared
    @Environment(\.colorScheme) private var systemColorScheme
    
    private var currentPreference: ColorSchemePreference {
        switch appearanceManager.preferredColorScheme {
        case .light: return .light
        case .dark: return .dark
        case .none: return .system
        @unknown default: return .system
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(ColorSchemePreference.allCases) { preference in
                    Button {
                        appearanceManager.preferredColorScheme = preference.colorScheme
                    } label: {
                        HStack {
                            Image(systemName: preference.icon)
                                .foregroundStyle(preference == currentPreference ? .orange : .secondary)
                                .frame(width: 30)
                            
                            Text(preference.rawValue)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if preference == currentPreference {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            } header: {
                Text("Appearance")
            } footer: {
                Text("Choose how the app looks. System will match your device settings.")
            }
            
            Section {
                Toggle(isOn: $appearanceManager.useTrueDarkMode) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("True Dark Mode")
                        Text("Use pure black background for OLED displays")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.orange)
            }
            
            // Preview
            Section {
                ColorSchemePreview()
            } header: {
                Text("Preview")
            }
        }
        .navigationTitle("Appearance")
    }
}

// MARK: - Color Scheme Preview

struct ColorSchemePreview: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Light preview
            PreviewCard(title: "Light", scheme: .light)
            
            // Dark preview
            PreviewCard(title: "Dark", scheme: .dark)
        }
        .padding(.vertical, 8)
    }
}

struct PreviewCard: View {
    let title: String
    let scheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(scheme == .dark ? Color(white: 0.1) : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                
                VStack(spacing: 4) {
                    Circle()
                        .fill(.orange)
                        .frame(width: 20, height: 20)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(scheme == .dark ? Color(white: 0.3) : Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(scheme == .dark ? Color(white: 0.3) : Color.gray.opacity(0.3))
                        .frame(width: 40, height: 8)
                }
                .padding(12)
            }
            .frame(height: 80)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
