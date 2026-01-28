# AlarmKit Limitations & Archive Notice

## Project Status: ARCHIVED ⚠️

**Snooze If You Can** is currently archived until Apple releases a fully functional version of AlarmKit that allows third-party developers to create alarm experiences comparable to the native iOS Clock app.

## Background

At WWDC 2024, Apple announced **AlarmKit** - a new framework designed to let developers create alarm experiences that integrate with the iOS system, similar to the native Clock app. This was exciting news for apps like Snooze If You Can that aim to provide custom alarm functionality.

## Current AlarmKit Issues (January 2026)

Despite being announced for iOS 18, AlarmKit has significant limitations that prevent it from being production-ready:

### 1. Entitlement Restrictions
- AlarmKit requires special entitlements that are not automatically granted
- Many developers report entitlement requests being denied
- Unclear criteria for who gets access to the framework

### 2. Simulator Limitations
- AlarmKit is completely non-functional in the iOS Simulator
- Testing requires physical devices only
- Makes development and debugging extremely difficult

### 3. Incomplete Implementation
- Framework appears to be in beta state despite iOS 18 being released
- Missing APIs and incomplete documentation
- Unpredictable behavior across different iOS versions

### 4. System Integration Issues
- Alarms created with AlarmKit don't appear in the native Clock app
- Users can't manage alarms from both apps simultaneously
- Confusing user experience with duplicate alarm systems

### 5. Live Activities Limitations
- Integration with Dynamic Island is incomplete
- Lock Screen widgets don't work as documented
- Live Activities for alarm countdown are unreliable

## Our Implementation Strategy

Given these limitations, we implemented a **hybrid fallback approach**:

### Primary: AlarmKit (iOS 18+ with entitlements)
```swift
if #available(iOS 18.0, *), AlarmKitService.shared.isAuthorized {
    try await AlarmKitService.shared.scheduleAlarm(alarm)
}
```

### Fallback: UserNotifications + Critical Alerts
```swift
else {
    NotificationManager.shared.scheduleAlarm(alarm)
    NotificationManager.shared.requestPermission(allowCritical: true)
}
```

### In-App UI
- Full-screen `ActiveAlarmView` when alarm fires
- Handles snooze and dismiss actions
- Works regardless of AlarmKit availability

## Why This Isn't Sufficient

While the fallback approach works, it has critical limitations:

1. **Not a True Alarm**
   - Notifications can be cleared by the user
   - System can delay or drop notifications under resource pressure
   - No guaranteed alarm behavior like native Clock app

2. **Background Limitations**
   - App can be terminated by iOS
   - Background refresh is not guaranteed
   - Cannot wake device from deep sleep reliably

3. **User Trust**
   - Users (rightfully) don't trust third-party apps for critical wake-up alarms
   - Native Clock app has special system privileges we can't access
   - Missing the "it just works" reliability of Apple's implementation

4. **Critical Alerts Abuse**
   - Critical Alerts are designed for emergencies (health, safety, security)
   - Using them for alarm apps may violate App Store guidelines
   - Apple may reject apps that misuse this permission

## What We Need from Apple

For this project to be un-archived and production-ready, we need:

1. ✅ **Public AlarmKit Entitlements**
   - Clear process for requesting entitlements
   - Transparent approval criteria
   - Reasonable approval timeline

2. ✅ **Full Simulator Support**
   - AlarmKit working in iOS Simulator
   - Proper testing and debugging capabilities
   - Consistent behavior with physical devices

3. ✅ **Complete API Surface**
   - All promised APIs implemented
   - Comprehensive documentation
   - Sample code and best practices

4. ✅ **System Integration**
   - Option for alarms to appear in native Clock app
   - Unified alarm management experience
   - Clear communication to users about alarm sources

5. ✅ **Reliability Guarantees**
   - Documentation of guaranteed alarm delivery
   - SLA for alarm firing accuracy
   - Fallback mechanisms for system failures

## Current Alternatives

For users who need a reliable alarm:

1. **Use the native Clock app** - It's the only truly reliable option
2. **Use this app as a secondary alarm** - Not as your primary wake-up method
3. **Wait for Apple to fix AlarmKit** - Follow this repo for updates

## When Will This Be Un-archived?

We'll un-archive and continue development when:

- Apple releases a stable AlarmKit with public entitlements
- We can reliably test in both Simulator and device
- The framework provides guarantees comparable to native alarms
- App Store guidelines clearly allow alarm apps with proper permissions

## Alternatives Considered

### Option 1: Ship Without AlarmKit
**Status**: ❌ Rejected  
**Reason**: Misleading to users; can't guarantee alarm reliability

### Option 2: Health & Safety Exception
**Status**: ❌ Not Applicable  
**Reason**: Alarm apps don't qualify for Critical Alert exception

### Option 3: Open Source and Archive
**Status**: ✅ **CHOSEN**  
**Reason**: Transparent about limitations; preserves work; educates community

## For Other Developers

If you're building an alarm app, please be aware:

- **Don't promise what you can't deliver** - Be honest about limitations
- **Test on physical devices** - Simulator won't show AlarmKit issues
- **Have a backup plan** - UserNotifications as fallback
- **Monitor WWDC and iOS releases** - Watch for AlarmKit improvements
- **Join the feedback loop** - File radars with Apple about AlarmKit issues

## Contributing

Despite being archived, we welcome contributions that:
- Improve code quality and documentation
- Add features that work with current limitations
- Prepare for future AlarmKit improvements
- Help other developers understand the challenges

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Stay Updated

- **GitHub Issues**: We track AlarmKit updates in issues
- **WWDC**: Watch for AlarmKit announcements
- **iOS Betas**: Test new iOS versions for improvements
- **Twitter/X**: Follow iOS developer community discussions

## Questions?

Open an issue with the `alarmkit-question` label and we'll help as we can.

---

**Last Updated**: January 28, 2026  
**iOS Version**: 18.2  
**AlarmKit Status**: Beta/Unstable  
**Project Status**: Archived
