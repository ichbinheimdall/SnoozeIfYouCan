# 🚀 Quick Start Guide

Get **Snooze If You Can** up and running in 5 minutes!

## Prerequisites

Before you begin, make sure you have:

- ✅ **Xcode 16.0+** installed
- ✅ **macOS Sonoma** or later
- ✅ **iOS 18.0+** physical device (AlarmKit doesn't work in Simulator)
- ✅ **Apple Developer account** (free or paid)
- ✅ **iCloud account** for testing sync features

## Step 1: Clone the Repository

```bash
git clone https://github.com/ichbinheimdall/SnoozeIfYouCan.git
cd SnoozeIfYouCan
```

## Step 2: Open in Xcode

```bash
open SnoozeIfYouCan.xcodeproj
```

Wait for Xcode to index the project (should take 10-30 seconds).

## Step 3: Configure Code Signing

1. Select the **SnoozeIfYouCan** project in the navigator
2. Select the **SnoozeIfYouCan** target
3. Go to **Signing & Capabilities** tab
4. Choose your **Team** from the dropdown
5. Xcode will automatically create a provisioning profile

### Update Bundle Identifier (Optional)

If you get signing errors:

1. Change **Bundle Identifier** to something unique
   - Example: `com.yourname.SnoozeIfYouCan`
2. Repeat for all targets:
   - SnoozeIfYouCan
   - SnoozeIfYouCanWatch
   - SnoozeAlarmWidget

## Step 4: Configure Capabilities

### Required Capabilities

Make sure these are enabled (should be by default):

1. **Push Notifications**
   - ✅ Enabled
   
2. **Background Modes**
   - ✅ Background fetch
   - ✅ Remote notifications
   
3. **iCloud**
   - ✅ CloudKit
   - Container: `iCloud.com.snoozeifyoucan.app` (or your custom identifier)

### Update iCloud Container (Optional)

If you want to use your own iCloud container:

1. Create a new container in **Capabilities → iCloud**
2. Update container identifier in `CloudKitManager.swift`:
   ```swift
   container = CKContainer(identifier: "iCloud.YOUR-BUNDLE-ID")
   ```

## Step 5: Connect Your Device

1. Connect your iPhone via USB or Wi-Fi
2. Unlock your device and trust the computer
3. Select your device from the device menu in Xcode
4. Click **Run** (Cmd+R) or press the Play button

### Build Settings

If build fails:

1. Select iOS deployment target **18.0** or higher
2. Ensure you're building for **Debug** configuration
3. Check that your device iOS version is 18.0+

## Step 6: Grant Permissions

When the app launches for the first time:

1. **Complete onboarding**: Tap through the intro screens
2. **Allow notifications**: Tap "Enable Notifications"
   - This is critical for alarm delivery!
3. **Confirm permission**: Tap "Allow" in the system dialog

### Optional: Enable Critical Alerts

For best alarm reliability (requires special entitlement):

1. Go to iPhone **Settings → SnoozeIfYouCan → Notifications**
2. Enable **Critical Alerts**
3. This allows alarms to break through Do Not Disturb

## Step 7: Create Your First Alarm

1. Tap the **+** button in the top-right
2. Set your desired time using the picker
3. Add a label (e.g., "Morning Workout")
4. Optionally select repeat days
5. Tap **Save**

Your alarm is now scheduled! 🎉

## Step 8: Test the Alarm

⚠️ **Important**: For testing, set an alarm 1-2 minutes in the future.

### What to Expect

When the alarm fires:
1. You'll see a notification (if app is in background)
2. Tapping the notification opens the full-screen alarm view
3. You can:
   - **"I'm Awake!"** - Dismiss for free
   - **"Snooze"** - Pay to snooze (9 minutes)

### Testing Snooze Flow

1. When alarm fires, tap **Snooze**
2. Confirm the payment (uses Sandbox in Debug builds)
3. The app schedules a snooze for 9 minutes later
4. Each snooze costs progressively more
5. After 5 snoozes, snoozing is disabled

## Troubleshooting

### "AlarmKit Not Available"

**Cause**: AlarmKit doesn't work in iOS Simulator or without proper entitlements

**Solution**: This is expected! The app automatically falls back to UserNotifications.

### Notifications Not Appearing

**Solutions**:
- Check notification permissions in Settings
- Disable Do Not Disturb / Focus modes
- Enable Critical Alerts
- Make sure the app has Background App Refresh enabled
- Try restarting your device

### Build Errors

**Common issues**:

1. **Provisioning Profile Issues**
   - Solution: Change bundle identifier and select your team

2. **Missing Capabilities**
   - Solution: Enable Push Notifications and iCloud in Capabilities

3. **iOS Version Mismatch**
   - Solution: Update device to iOS 18+ or lower deployment target

### App Crashes on Launch

**Possible causes**:
- CloudKit container misconfigured
- StoreKit products not loaded
- Corrupt UserDefaults data

**Solution**: 
1. Delete the app from your device
2. Clean build folder (Cmd+Shift+K)
3. Build and run again

## Next Steps

### Explore Features

- 📊 **Impact Dashboard**: View your donation statistics
- 🏆 **Achievements**: Earn badges for milestones
- ⚙️ **Settings**: Customize sounds, themes, and charity selection
- 👥 **Social**: Add accountability partners

### Development

- Read [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines
- Check [ARCHITECTURE.md](ARCHITECTURE.md) to understand the codebase
- Review [ALARMKIT_LIMITATIONS.md](ALARMKIT_LIMITATIONS.md) for technical details

### Testing on Multiple Devices

The app supports iCloud sync:

1. Sign in with the same iCloud account on multiple devices
2. Install the app on each device
3. Alarms and statistics will sync automatically
4. Test cross-device alarm management

## StoreKit Configuration (Optional)

To test payments properly:

### Create Sandbox Products

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create an app record
3. Go to **In-App Purchases**
4. Create 5 consumable products:
   - `com.snoozeifyoucan.donation.tier1` - $0.99
   - `com.snoozeifyoucan.donation.tier2` - $1.99
   - `com.snoozeifyoucan.donation.tier3` - $2.99
   - `com.snoozeifyoucan.donation.tier4` - $4.99
   - `com.snoozeifyoucan.donation.tier5` - $9.99

### Test Payments

1. Create a Sandbox tester account in App Store Connect
2. Sign out of App Store on your device
3. Launch the app and trigger a snooze
4. Sign in with sandbox account when prompted
5. Complete the test purchase

## Apple Watch Setup (Optional)

The project includes a Watch app:

1. Pair an Apple Watch running watchOS 10+
2. Select **SnoozeIfYouCanWatch** scheme in Xcode
3. Build and run on the Watch
4. Alarms sync between iPhone and Watch

## Widget Setup (Optional)

To see the home screen widget:

1. Long-press on home screen
2. Tap **+** to add widget
3. Find **Snooze If You Can**
4. Select widget size and tap **Add Widget**
5. Widget shows next scheduled alarm

## Learn More

- **README**: [README.md](README.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Architecture**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **Status**: [PROJECT_STATUS.md](PROJECT_STATUS.md)

## Getting Help

If you're stuck:

1. Check the **Troubleshooting** section above
2. Search [GitHub Issues](https://github.com/ichbinheimdall/SnoozeIfYouCan/issues)
3. Open a new issue with:
   - iOS version
   - Xcode version
   - Steps to reproduce
   - Error messages or screenshots

## Ready to Contribute?

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Code style guidelines
- Pull request process
- Areas that need help

---

**Happy coding! If you encounter issues, we're here to help.** 🚀
