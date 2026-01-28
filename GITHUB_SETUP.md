# GitHub Repository Setup Guide

Quick reference for setting up the GitHub repository when publishing.

## Repository Settings

### Basic Information

**Repository Name**: `SnoozeIfYouCan`

**Description**:
```
⏰ iOS alarm app that turns snoozing into charitable donations. Built with SwiftUI & AlarmKit. Currently archived pending Apple's AlarmKit improvements.
```

**Website**: [Your project website or leave blank]

**Topics** (Add these tags):
- `ios`
- `swift`
- `swiftui`
- `alarmkit`
- `ios-app`
- `charity`
- `alarm-clock`
- `swift6`
- `mvvm`
- `storekit2`
- `cloudkit`

### Repository Options

- [x] **Public** (not Private)
- [x] **Include README** (already created)
- [x] **Include LICENSE** (MIT already added)
- [x] **Include .gitignore** (Swift already added)
- [x] **Enable Issues**
- [x] **Enable Discussions**
- [ ] **Enable Projects** (optional)
- [ ] **Enable Wiki** (optional)

## Branch Protection (Optional)

For `main` branch:
- [ ] Require pull request reviews
- [ ] Require status checks to pass
- [ ] Require conversation resolution
- [ ] Do not allow force pushes

## Issue Templates

Create these in `.github/ISSUE_TEMPLATE/`:

### 1. Bug Report (`bug_report.md`)

```markdown
---
name: Bug Report
about: Report a bug or unexpected behavior
title: '[BUG] '
labels: bug
assignees: ''
---

**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Tap on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
 - Device: [e.g. iPhone 15 Pro]
 - iOS: [e.g. iOS 18.2]
 - App Version: [e.g. 0.1.0]

**Additional context**
Any other relevant information.
```

### 2. Feature Request (`feature_request.md`)

```markdown
---
name: Feature Request
about: Suggest an enhancement or new feature
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
What you want to happen.

**Describe alternatives you've considered**
Other approaches you've thought about.

**Additional context**
Any other context, mockups, or examples.
```

### 3. AlarmKit Update (`alarmkit_update.md`)

```markdown
---
name: AlarmKit Update
about: Report changes or improvements to Apple's AlarmKit
title: '[ALARMKIT] '
labels: alarmkit
assignees: ''
---

**iOS Version**
Which iOS version did you test?

**What changed?**
What AlarmKit improvement or change did you observe?

**Test Details**
- Device tested
- Steps to verify
- Behavior observed

**Screenshots/Logs**
Any evidence of the change.
```

## Pull Request Template

Create `.github/pull_request_template.md`:

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement

## Testing
- [ ] Tested on physical device
- [ ] Tested alarm creation/editing
- [ ] Tested snooze flow
- [ ] Checked VoiceOver support
- [ ] Verified dark mode

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings introduced

## Screenshots (if applicable)
Add screenshots of UI changes.
```

## Labels to Create

Create these labels in GitHub:

| Label | Color | Description |
|-------|-------|-------------|
| `bug` | #d73a4a | Something isn't working |
| `enhancement` | #a2eeef | New feature or request |
| `documentation` | #0075ca | Documentation improvements |
| `good first issue` | #7057ff | Good for newcomers |
| `help wanted` | #008672 | Extra attention needed |
| `alarmkit` | #e99695 | AlarmKit-related issues |
| `question` | #d876e3 | Further information requested |
| `wontfix` | #ffffff | This will not be worked on |
| `duplicate` | #cfd3d7 | Duplicate issue |
| `archived-notice` | #fbca04 | Related to project archival |

## GitHub Actions (Optional)

Create `.github/workflows/build.yml`:

```yaml
name: iOS Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode.app
    
    - name: Build
      run: xcodebuild -project SnoozeIfYouCan.xcodeproj -scheme SnoozeIfYouCan -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

## Social Media Posts

### Twitter/X Template

```
🚀 Just open-sourced "Snooze If You Can" - an iOS alarm app that turns snoozing into charitable donations!

⏰ Escalating snooze costs ($0.99 → $9.99)
💚 Donations support education
📱 Built with SwiftUI & AlarmKit

⚠️ Currently archived pending AlarmKit improvements from Apple

#iOSDev #Swift #OpenSource

[GitHub Link]
```

### Reddit r/iOSProgramming Template

```
Title: [Open Source] Snooze If You Can - iOS Alarm App with Charitable Donations (Archived)

I've just open-sourced my iOS alarm app project that demonstrates using Apple's new AlarmKit framework. The concept is simple: every time you snooze, you donate to charity, with costs escalating ($0.99 to $9.99) to discourage excessive snoozing.

**Key Features:**
- SwiftUI + MVVM architecture
- AlarmKit integration with UserNotifications fallback
- StoreKit 2 for in-app purchases
- CloudKit sync
- Full localization and accessibility support

**Why Archived:**
The project is currently archived because AlarmKit isn't production-ready yet (no simulator support, unclear entitlements, reliability issues). It's more of a reference implementation and learning resource at this stage.

**What's Inside:**
- ~5,000 lines of Swift 6.0 code
- Comprehensive documentation (11 markdown files)
- Clean architecture following iOS best practices
- Complete feature set (just needs reliable AlarmKit)

**For Developers:**
If you're interested in AlarmKit, this project shows how to implement it with proper fallbacks. It also demonstrates StoreKit 2, CloudKit, and modern SwiftUI patterns.

GitHub: [Link]

Feedback and contributions welcome!
```

## README Badges

Add to top of README.md:

```markdown
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2018.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Status](https://img.shields.io/badge/Status-Archived-yellow.svg)](PROJECT_STATUS.md)
```

## Initial Release

Create a release `v0.1.0`:

**Release Title**: `v0.1.0 - Initial Release (Archived)`

**Release Notes**:
```markdown
# 🎉 Initial Release

This is the first public release of **Snooze If You Can**.

## ⚠️ Archive Notice

This project is archived pending Apple's improvements to AlarmKit. While all features are implemented and working, the app cannot guarantee reliable alarm delivery due to AlarmKit limitations.

## ✨ Features

- Complete alarm management (create, edit, delete)
- Escalating snooze costs ($0.99 → $9.99)
- Maximum 5 snoozes per alarm
- Donation tracking and statistics
- iCloud sync via CloudKit
- StoreKit 2 payment integration
- Turkish and English localization
- Full accessibility support
- Apple Watch and Widget extensions

## 📚 Documentation

- [README](README.md) - Project overview
- [QUICKSTART](QUICKSTART.md) - 5-minute setup
- [ARCHITECTURE](ARCHITECTURE.md) - Technical deep-dive
- [ALARMKIT_LIMITATIONS](ALARMKIT_LIMITATIONS.md) - Why archived

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

## 🔗 Links

- [Report Bug](https://github.com/ichbinheimdall/SnoozeIfYouCan/issues/new?template=bug_report.md)
- [Request Feature](https://github.com/ichbinheimdall/SnoozeIfYouCan/issues/new?template=feature_request.md)
- [Discussions](https://github.com/ichbinheimdall/SnoozeIfYouCan/discussions)
```

## First Commits

Suggested commit structure:

```bash
# Initial commit
git add .
git commit -m "Initial commit: Snooze If You Can v0.1.0

- Complete iOS alarm app with charitable donation mechanic
- AlarmKit integration with UserNotifications fallback
- StoreKit 2 payment processing
- CloudKit sync support
- Full documentation and open source compliance
- Project archived pending AlarmKit improvements"

git push origin main

# Tag release
git tag -a v0.1.0 -m "Initial release"
git push origin v0.1.0
```

## Monitoring

After publishing, monitor:

- ⭐ **Stars** - Interest in project
- 👁️ **Watchers** - Active followers
- 🍴 **Forks** - Derivatives/experiments
- 📊 **Traffic** - Views and clones
- 💬 **Issues** - Bug reports and questions
- 🔀 **Pull Requests** - Community contributions

## Promotion Channels

Share on:

- [ ] Twitter/X
- [ ] Reddit r/iOSProgramming
- [ ] Hacker News
- [ ] Swift Forums
- [ ] iOS Dev Slack/Discord communities
- [ ] LinkedIn
- [ ] Dev.to
- [ ] Medium (write article)

---

**Ready to publish? Follow this checklist and you're all set!** 🚀
