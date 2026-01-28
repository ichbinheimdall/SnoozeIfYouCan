# Architecture Documentation

## Overview

**Snooze If You Can** is a native iOS application built with SwiftUI and Swift 6.0, following modern iOS development best practices. The app uses MVVM architecture with reactive state management via Combine and SwiftUI's property wrappers.

## Architecture Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                     │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────┐             │
│  │ AlarmList  │  │ ActiveAlarm │  │    Impact    │             │
│  │   View     │  │    View     │  │  Dashboard   │  ...        │
│  └────────────┘  └─────────────┘  └──────────────┘             │
│         │               │                  │                   │
└─────────┼───────────────┼──────────────────┼───────────────────┘
          │               │                  │
          ▼               ▼                  ▼
┌────────────────────────────────────────────────────────────────┐
│                        Business Logic Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ AlarmManager │  │PaymentManager│  │ CloudKit     │          │
│  │ (Observable) │  │ (Observable) │  │  Manager     │  ...     │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         │                  │                 │                 │
└─────────┼──────────────────┼─────────────────┼─────────────────┘
          │                  │                 │
          ▼                  ▼                 ▼
┌────────────────────────────────────────────────────────────────┐
│                          Service Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  AlarmKit    │  │  StoreKit 2  │  │  CloudKit    │          │
│  │  Service     │  │   (Apple)    │  │   (Apple)    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         │                                   │                  │
│         ▼                                   ▼                  │
│  ┌──────────────┐                  ┌──────────────┐            │
│  │UserNotific.  │                  │ UserDefaults │            │
│  │  (Fallback)  │                  │ (Local Cache)│            │
│  └──────────────┘                  └──────────────┘            │
└────────────────────────────────────────────────────────────────┘
```

## Layer Responsibilities

### 1. Presentation Layer (Views)

**Technology**: SwiftUI

**Responsibilities**:
- Render UI components
- Handle user interactions
- Observe state changes from managers
- Display loading/error states
- Accessibility (VoiceOver support)

**Key Views**:
- `AlarmListView`: Main alarm list (iOS Clock-style)
- `ActiveAlarmView`: Full-screen alarm when fired
- `AlarmEditView`: Add/edit alarm details
- `ImpactDashboardView`: Donation statistics and charts
- `SettingsView`: App configuration
- `OnboardingView`: First-run experience

**State Management**:
```swift
@EnvironmentObject var alarmManager: AlarmManager
@EnvironmentObject var paymentManager: PaymentManager
@State private var showingAddAlarm = false
```

### 2. Business Logic Layer (Managers)

**Technology**: Swift + Combine

**Responsibilities**:
- Core business logic
- State management with `@Published` properties
- Coordinate between services
- Data transformation
- Error handling
- Persistence orchestration

**Key Managers**:

#### AlarmManager
- CRUD operations for alarms
- Snooze logic with escalating costs
- Statistics tracking
- AlarmKit/Notification scheduling coordination
- Local persistence via UserDefaults

#### PaymentManager
- StoreKit 2 integration
- Product loading and caching
- Purchase flows
- Transaction verification
- Purchase restoration

#### CloudKitManager
- iCloud synchronization
- Conflict resolution
- Background sync
- Account status monitoring

#### Other Managers
- `SoundManager`: Audio playback
- `HapticsManager`: Haptic feedback
- `WatchConnectivityManager`: Apple Watch sync

### 3. Service Layer

**Technology**: Apple frameworks + wrappers

**Responsibilities**:
- Framework integration
- API abstraction
- Platform-specific code
- Error translation

#### AlarmKitService (iOS 26+)

Wraps Apple's AlarmKit framework:

```swift
@available(iOS 26.0, *)
final class AlarmKitService: ObservableObject {
    func scheduleAlarm(_ alarm: Alarm) async throws
    func cancelAlarm(_ alarm: Alarm)
    func snoozeAlarm(_ alarm: Alarm)
    func stopAlarm(_ alarm: Alarm)
}
```

**Fallback Strategy**:
```swift
enum AlarmServiceHelper {
    static func scheduleAlarm(_ alarm: Alarm) async throws {
        if #available(iOS 26.0, *), AlarmKitService.shared.isAuthorized {
            try await AlarmKitService.shared.scheduleAlarm(alarm)
        } else {
            NotificationManager.shared.scheduleAlarm(alarm)
        }
    }
}
```

#### NotificationManager

Fallback implementation using UserNotifications:

```swift
final class NotificationManager {
    func scheduleAlarm(_ alarm: Alarm)
    func cancelAlarm(_ alarm: Alarm)
    func scheduleSnooze(_ alarm: Alarm, minutes: Int)
    func requestPermission(allowCritical: Bool)
}
```

## Data Flow

### Alarm Creation Flow

```
User taps "+" → AlarmEditView presented
                      ↓
User configures alarm details (time, label, repeat)
                      ↓
User taps "Save" → AlarmManager.addAlarm(_)
                      ↓
AlarmManager persists to UserDefaults
                      ↓
AlarmManager calls scheduleAlarmNotification(_)
                      ↓
AlarmServiceHelper routes to AlarmKit or Notifications
                      ↓
System schedules alarm
```

### Alarm Firing Flow

```
System fires alarm (AlarmKit or Notification)
                      ↓
AppDelegate receives notification
                      ↓
Posts NotificationCenter.alarmDidFire
                      ↓
MainTabView observes notification
                      ↓
Presents ActiveAlarmView (full-screen)
                      ↓
SoundManager plays alarm sound
                      ↓
HapticsManager vibrates device
```

### Snooze Flow

```
User taps "Snooze" in ActiveAlarmView
                      ↓
Check if max snoozes reached (5 max)
                      ↓
Get next snooze cost from AlarmManager
                      ↓
Show confirmation alert with cost
                      ↓
User confirms → PaymentManager.purchaseSnooze(cost)
                      ↓
StoreKit 2 processes payment
                      ↓
On success: AlarmManager.snoozeAlarm(_)
                      ↓
Update snooze count, record donation
                      ↓
Schedule snooze (9 minutes later)
                      ↓
Dismiss ActiveAlarmView
```

## Data Models

### Core Models

#### Alarm
```swift
struct Alarm: Identifiable, Codable {
    var id: UUID
    var time: Date
    var label: String
    var isEnabled: Bool
    var repeatDays: Set<Weekday>
    var snoozeCost: Double
    var snoozeCount: Int
    var lastSnoozeDate: Date?
}
```

#### UserStats (DonationStats)
```swift
struct DonationStats: Codable {
    var totalDonated: Double
    var totalSnoozes: Int
    var currentStreak: Int
    var longestStreak: Int
    var currentWeekAmount: Double
    var currentMonthAmount: Double
}
```

#### SnoozeRecord
```swift
struct SnoozeRecord: Codable {
    let alarmId: UUID
    let date: Date
    let amount: Double
}
```

#### Charity
```swift
struct Charity: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: CharityCategory
    let websiteURL: URL?
}
```

## Persistence Strategy

### Local Storage (UserDefaults)

**Used For**:
- Alarms array
- Snooze records
- Statistics
- App preferences
- Onboarding state

**Format**: JSON via `Codable`

**Example**:
```swift
private func saveAlarms() {
    if let data = try? JSONEncoder().encode(alarms) {
        UserDefaults.standard.set(data, forKey: alarmsKey)
    }
}
```

**Limitations**:
- Not designed for large datasets
- No encryption (iOS sandboxing provides isolation)
- Synchronous API

### Cloud Storage (CloudKit)

**Used For**:
- Cross-device sync of alarms
- Backup of snooze records
- Statistics synchronization

**Container**: `iCloud.com.snoozeifyoucan.app`

**Record Types**:
- `Alarm`: Alarm configuration
- `SnoozeRecord`: Snooze history
- `UserStats`: Statistics

**Conflict Resolution**: Last-write-wins with merge logic

## Threading Model

### Main Actor

Most managers use `@MainActor`:

```swift
@MainActor
final class AlarmManager: ObservableObject {
    // All methods run on main thread
    // Safe UI updates from @Published properties
}
```

### Async/Await

Used for asynchronous operations:

```swift
func scheduleAlarm(_ alarm: Alarm) async throws {
    try await AlarmKitService.shared.scheduleAlarm(alarm)
}
```

### Background Tasks

- CloudKit sync: Uses background URL sessions
- Transaction updates: StoreKit 2 task detached
- Alarm scheduling: System-level background execution

## Dependency Injection

### Environment Objects

```swift
@main
struct SnoozeIfYouCanApp: App {
    @StateObject private var alarmManager = AlarmManager()
    @StateObject private var paymentManager = PaymentManager.shared
    @StateObject private var soundManager = SoundManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(alarmManager)
                .environmentObject(paymentManager)
                .environmentObject(soundManager)
        }
    }
}
```

### Singletons

Used for stateless services:

```swift
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    private init() { }
}
```

## Error Handling

### Throwing Functions

```swift
func scheduleAlarm(_ alarm: Alarm) async throws {
    if #available(iOS 26.0, *) {
        try await AlarmKitService.shared.scheduleAlarm(alarm)
    } else {
        // Fallback doesn't throw
        NotificationManager.shared.scheduleAlarm(alarm)
    }
}
```

### Published Errors

```swift
@Published var lastError: String?

func loadProducts() async {
    do {
        products = try await Product.products(for: productIDs)
    } catch {
        lastError = error.localizedDescription
    }
}
```

### User Feedback

- Alerts for critical errors
- Toast messages for minor issues
- Inline error states in views
- Haptic feedback for validation errors

## Testing Strategy

### Unit Tests

**Target**: Business logic in managers

```swift
@testable import SnoozeIfYouCan

class AlarmManagerTests: XCTestCase {
    func testSnoozeCostEscalation() {
        let manager = AlarmManager()
        var alarm = Alarm(time: Date(), label: "Test")
        
        XCTAssertEqual(manager.getNextSnoozeCost(for: alarm), 0.99)
        alarm.snoozeCount = 1
        XCTAssertEqual(manager.getNextSnoozeCost(for: alarm), 1.99)
    }
}
```

### UI Tests

**Target**: Critical user flows

```swift
class AlarmFlowUITests: XCTestCase {
    func testCreateAlarm() {
        let app = XCUIApplication()
        app.launch()
        
        app.buttons["Add"].tap()
        app.datePickers.firstMatch.adjust(toPickerWheelValue: "7:00 AM")
        app.buttons["Save"].tap()
        
        XCTAssertTrue(app.staticTexts["7:00 AM"].exists)
    }
}
```

### Manual Testing

- Physical device testing (AlarmKit doesn't work in simulator)
- Different iOS versions
- Dark mode and accessibility
- Low power mode and background termination

## Performance Considerations

### View Performance

- Use `LazyVStack` for large lists
- Minimize view body complexity
- Extract subviews for reusability
- Use `EquatableView` where appropriate

### Data Performance

- UserDefaults suitable for < 1MB of data
- CloudKit batches operations
- Lazy loading for snooze records
- Pagination for long lists (future)

### Memory Management

- Weak references in closures
- Cancel Combine subscriptions
- Deallocate large resources (audio files)
- Monitor with Instruments

## Security Architecture

### Data Protection

- iOS sandboxing isolates app data
- CloudKit encrypted end-to-end by Apple
- No custom encryption implemented
- Keychain not used (no secrets stored)

### Payment Security

- StoreKit 2 handles all payment processing
- No credit card data in app
- Client-side transaction verification
- Server-side verification recommended (future)

### Privacy

- No analytics tracking
- No user accounts or authentication
- No data shared with third parties
- Data export available on request

## Scalability

### Current Limitations

- UserDefaults limited to ~1MB
- CloudKit free tier: 10GB storage, 2GB transfer
- No pagination on alarm list
- No search functionality

### Future Improvements

- Core Data for larger datasets
- Server backend for donation verification
- Multiple charity support
- Team/social features

## Deployment

### Build Configurations

- **Debug**: Development builds with verbose logging
- **Release**: Production builds with optimizations

### App Store Distribution

1. Code signing with distribution certificate
2. Archive build in Xcode
3. Upload to App Store Connect
4. Configure App Store metadata
5. Submit for review

### TestFlight

- Distribute beta builds to testers
- Gather feedback before App Store release
- Test on wide range of devices and iOS versions

## Monitoring

### Crash Reporting

Recommended: Firebase Crashlytics or Sentry

### Analytics

None currently (privacy-focused)

### Logging

```swift
print("✅ Success message")
print("⚠️ Warning message")
print("❌ Error message")
```

Production: Consider OSLog for structured logging

## Future Architecture Improvements

1. **Core Data Migration**: Replace UserDefaults for better performance
2. **Server Backend**: Verify donations, enable social features
3. **Repository Pattern**: Abstract data layer for easier testing
4. **Coordinator Pattern**: Improve navigation and deep linking
5. **Modular Architecture**: Extract features into Swift packages
6. **GraphQL/REST API**: Connect to charity partners
7. **Real-time Sync**: Use CloudKit subscriptions for instant updates

---

**Last Updated**: January 28, 2026  
**Version**: 0.1.0
