# ⏰ Snooze If You Can

> **⚠️ PROJECT STATUS: ARCHIVED**  
> This project is currently archived pending Apple's official release and proper implementation of AlarmKit. While the app demonstrates the concept, it cannot function as a true alarm replacement due to AlarmKit limitations in iOS 18.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2018.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Snooze If You Can** is an iOS alarm app that transforms your snooze habit into charitable donations. Every time you hit snooze, a small donation goes to Darüşşafaka, supporting education for children in need.

## 📱 Features

- ⏰ **Smart Alarms**: Set repeating or one-time alarms with custom labels and sounds
- 💰 **Escalating Snooze Costs**: Each snooze costs progressively more ($0.99 → $9.99)
- 🎯 **Max 5 Snoozes**: After 5 snoozes, you must wake up!
- 💚 **Charitable Impact**: 100% of snooze payments support education at [Darüşşafaka](https://www.darussafaka.org)
- 📊 **Impact Dashboard**: Track your donations, streaks, and wake-up statistics
- 🏆 **Achievements**: Earn badges for wake-up milestones
- 👥 **Social Accountability**: Share your progress with friends
- ☁️ **iCloud Sync**: Alarms and stats sync across devices
- 🎨 **Native iOS Design**: Built with SwiftUI following Apple's Human Interface Guidelines
- ♿️ **Accessibility**: Full VoiceOver support and high contrast mode

## 🚨 Current Limitations

### AlarmKit Status

Apple announced AlarmKit at WWDC 2024 for iOS 18, but as of January 2026, the framework has significant limitations:

1. **Not Available on Simulator**: AlarmKit only works on physical devices
2. **Entitlement Issues**: Requires special entitlements that may not be granted to all developers
3. **System Integration**: Cannot fully replicate Apple's native Alarm app behavior
4. **Limited Testing**: Difficult to test thoroughly due to simulator restrictions

### Current Implementation

This app uses a **hybrid approach**:
- Attempts to use AlarmKit when available (iOS 18+)
- Falls back to UserNotifications with Critical Alerts
- Shows in-app full-screen alarm UI when notifications fire

**This is NOT a replacement for the native Clock app** until Apple releases a stable, fully-functional AlarmKit framework.

## 🏗️ Architecture

### Tech Stack

- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **Minimum iOS**: 18.0
- **Architecture**: MVVM with ObservableObject managers
- **Persistence**: UserDefaults (local) + CloudKit (sync)
- **Payments**: StoreKit 2 (consumable in-app purchases)
- **Frameworks**:
  - AlarmKit (iOS 18+, with fallback)
  - CloudKit (iCloud sync)
  - StoreKit 2 (donations)
  - UserNotifications (fallback alarm delivery)
  - WatchConnectivity (Apple Watch integration)

### Project Structure

```
SnoozeIfYouCan/
├── App/
│   └── SnoozeIfYouCanApp.swift          # Main app entry point
├── Models/
│   ├── Alarm.swift                       # Alarm data model
│   ├── UserStats.swift                   # Statistics tracking
│   ├── Charity.swift                     # Charity information
│   ├── Achievement.swift                 # Achievement system
│   └── SnoozeRecord.swift                # Snooze history
├── Services/
│   ├── AlarmManager.swift                # Alarm CRUD & logic
│   ├── AlarmKitService.swift             # AlarmKit wrapper
│   ├── NotificationManager.swift         # Notification fallback
│   ├── PaymentManager.swift              # StoreKit 2 integration
│   ├── CloudKitManager.swift             # iCloud sync
│   ├── SoundManager.swift                # Audio playback
│   └── HapticsManager.swift              # Haptic feedback
├── Views/
│   ├── Alarm/
│   │   ├── AlarmListView.swift           # Main alarm list
│   │   ├── AlarmEditView.swift           # Add/Edit alarm
│   │   └── ActiveAlarmView.swift         # Full-screen alarm UI
│   ├── Impact/
│   │   └── ImpactDashboardView.swift     # Donation stats
│   ├── Settings/
│   │   └── SettingsView.swift            # App settings
│   └── Onboarding/
│       └── OnboardingView.swift          # First-run experience
├── Design/
│   ├── Theme.swift                       # Colors, fonts, spacing
│   ├── Components.swift                  # Reusable UI components
│   └── Animations.swift                  # Custom animations
├── Localization/
│   ├── Localizable.swift                 # L10n wrapper
│   └── tr.lproj/                         # Turkish translations
└── Intents/
    ├── AlarmKitIntents.swift             # Stop/Snooze intents
    └── FocusFilter.swift                 # Focus Mode integration
```

## 🚀 Getting Started

### Prerequisites

- Xcode 16.0+
- iOS 18.0+ device (physical device recommended for AlarmKit testing)
- Apple Developer account (for notifications and AlarmKit entitlements)
- iCloud container configured (for sync)
- App Store Connect products configured (for donations)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ichbinheimdall/SnoozeIfYouCan.git
   cd SnoozeIfYouCan
   ```

2. **Open in Xcode**
   ```bash
   open SnoozeIfYouCan.xcodeproj
   ```

3. **Configure signing & entitlements**
   - Select your development team
   - Update bundle identifier
   - Configure iCloud container: `iCloud.com.snoozeifyoucan.app`
   - Enable capabilities:
     - Push Notifications
     - Background Modes (Background fetch, Remote notifications)
     - iCloud (CloudKit)

4. **Configure StoreKit**
   - Create consumable products in App Store Connect:
     - `com.snoozeifyoucan.donation.tier1` ($0.99)
     - `com.snoozeifyoucan.donation.tier2` ($1.99)
     - `com.snoozeifyoucan.donation.tier3` ($2.99)
     - `com.snoozeifyoucan.donation.tier4` ($4.99)
     - `com.snoozeifyoucan.donation.tier5` ($9.99)

5. **Build and run**
   - Select a physical iOS device (simulator has AlarmKit limitations)
   - Press Cmd+R to build and run

## 💡 How It Works

### The Snooze Mechanic

1. **Set an alarm** with a custom time and label
2. When the alarm fires, you see a **full-screen alarm view**
3. **Two choices**:
   - **"I'm Awake!"** - Dismiss the alarm for free, increase your streak
   - **"Snooze"** - Pay to snooze for 9 minutes (like iOS default)

### Escalating Costs

Each snooze costs progressively more to discourage excessive snoozing:

| Snooze # | Cost  |
|----------|-------|
| 1st      | $0.99 |
| 2nd      | $1.99 |
| 3rd      | $2.99 |
| 4th      | $4.99 |
| 5th      | $9.99 |
| 6th+     | ❌ Not allowed |

After 5 snoozes, the "Snooze" button is disabled - you must wake up!

### Charitable Impact

- 100% of snooze payments go to **Darüşşafaka**, a Turkish educational charity
- Track your total donations in the Impact Dashboard
- See weekly/monthly breakdowns
- Share your impact on social media

## 🎯 Roadmap (When AlarmKit is Ready)

- [ ] Full AlarmKit integration without fallbacks
- [ ] Live Activities for alarm countdown
- [ ] Dynamic Island support
- [ ] Lock Screen widgets
- [ ] Apple Watch complications
- [ ] Focus Mode integration
- [ ] Multiple charity options
- [ ] Team challenges
- [ ] Health app integration (sleep tracking)

## 🤝 Contributing

This project is open-source and contributions are welcome! However, please note that the project is currently archived pending AlarmKit improvements.

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Areas for Contribution

- [ ] Additional charity integrations
- [ ] More alarm sounds
- [ ] Advanced statistics and charts
- [ ] Localization (currently supports English and Turkish)
- [ ] Accessibility improvements
- [ ] UI/UX enhancements
- [ ] Unit and UI tests

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Darüşşafaka Society** - For their incredible work supporting education in Turkey
- **Apple** - For the AlarmKit framework (when it works!)
- **Community** - For supporting this project and the mission

## 📧 Contact

**HMD Developments**
- GitHub: [@ichbinheimdall](https://github.com/ichbinheimdall)
- Email: contact@hmddevs.org

## ⚠️ Disclaimer

This app is a proof-of-concept demonstrating the potential of AlarmKit for creating custom alarm experiences with social impact. It is **not intended to replace the iOS Clock app** for critical wake-up alarms until Apple releases a stable AlarmKit framework.

All donations are processed through Apple's In-App Purchase system. The developer is not responsible for donation distribution - this would require proper charity partnerships and payment processing in a production environment.

---

**Made with ❤️ for better mornings and brighter futures**
