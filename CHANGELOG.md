# Changelog

All notable changes to the Snooze If You Can project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive README with project overview and setup instructions
- LICENSE file (MIT License)
- CONTRIBUTING guidelines for open-source contributors
- ALARMKIT_LIMITATIONS documentation explaining archive status
- .gitignore for iOS/Swift development
- Export data functionality in Settings (exports to clipboard as JSON)

### Changed
- Improved code documentation across all files
- Enhanced error handling in AlarmKit integration
- Better comments explaining AlarmKit fallback strategy

### Fixed
- Removed unused ContentView.swift file
- Implemented TODO for data export in SettingsView

### Documentation
- Added inline documentation for all public APIs
- Explained AlarmKit limitations and workarounds
- Documented the hybrid fallback approach

## [0.1.0] - 2026-01-28

### Added
- Initial project structure
- AlarmKit integration with UserNotifications fallback
- Escalating snooze costs ($0.99 to $9.99)
- Maximum 5 snoozes per alarm
- Donation tracking to Darüşşafaka charity
- Full-screen alarm UI (ActiveAlarmView)
- Alarm list with iOS Clock-style design
- Impact dashboard showing donation statistics
- Settings screen with notification permissions
- Onboarding flow for first-time users
- iCloud sync via CloudKit
- StoreKit 2 integration for in-app purchases
- Apple Watch support (basic)
- Widget support (basic)
- Turkish and English localization
- Accessibility support with VoiceOver
- High contrast mode for better visibility
- Dark mode support
- Achievements system
- Social accountability features
- Statistics tracking (streaks, wake-up times)
- Custom alarm sounds
- Haptic feedback throughout app
- Focus Mode integration
- App Intents for Stop and Snooze actions

### Technical
- SwiftUI-based UI
- MVVM architecture
- Swift 6.0 with modern concurrency
- iOS 18.0+ minimum deployment target
- CloudKit for data synchronization
- StoreKit 2 for payments
- UserNotifications for alarm fallback
- WatchConnectivity for Apple Watch
- Combine for reactive updates

### Known Issues
- AlarmKit not available in iOS Simulator
- AlarmKit entitlements may not be granted
- Notification-based alarms not as reliable as native Clock app
- Cannot guarantee alarm fires when app is terminated
- Critical Alerts may face App Store review challenges

## Project Status

**ARCHIVED** - Pending Apple's release of fully functional AlarmKit with public entitlements.

This project demonstrates the concept and implementation but is not suitable for production use as a primary alarm app until AlarmKit limitations are resolved by Apple.

---

### Version History Legend

- **Added** - New features
- **Changed** - Changes to existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Vulnerability fixes
- **Documentation** - Documentation improvements
- **Technical** - Technical details and dependencies
