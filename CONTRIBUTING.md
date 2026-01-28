# Contributing to Snooze If You Can

First off, thank you for considering contributing to Snooze If You Can! It's people like you that make this project possible.

## Project Status

⚠️ **Important**: This project is currently archived pending Apple's full release and proper implementation of AlarmKit. While we welcome contributions, please understand that major features depending on AlarmKit may not be fully functional until Apple resolves the framework's limitations.

## Code of Conduct

This project and everyone participating in it is governed by a simple principle: **Be respectful and constructive**. We welcome all contributors regardless of background, experience level, or identity.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find that you don't need to create one. When you are creating a bug report, please include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** to demonstrate the steps
- **Describe the behavior you observed** and what behavior you expected
- **Include screenshots or animated GIFs** if relevant
- **Include your iOS version and device model**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful** to most users
- **List any similar features** in other apps if applicable

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. Ensure your code follows the project's coding style
4. Update documentation as needed
5. Write a clear commit message

## Development Setup

### Prerequisites

- Xcode 16.0 or later
- iOS 18.0+ device (physical device recommended)
- Apple Developer account
- Basic knowledge of Swift and SwiftUI

### Setup Steps

1. Clone your fork of the repository
   ```bash
   git clone https://github.com/ichbinheimdall/SnoozeIfYouCan.git
   cd SnoozeIfYouCan
   ```

2. Open the project in Xcode
   ```bash
   open SnoozeIfYouCan.xcodeproj
   ```

3. Configure signing with your development team

4. Build and run on a physical device (recommended)

## Coding Guidelines

### Swift Style Guide

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use Swift 6.0 features and syntax
- Prefer `struct` over `class` unless reference semantics are needed
- Use `@MainActor` for types that update UI
- Mark functions as `async` when performing asynchronous work

### SwiftUI Best Practices

- Break down large views into smaller, reusable components
- Use `@EnvironmentObject` for shared dependencies
- Prefer `@StateObject` over `@ObservedObject` for ownership
- Use proper view modifiers and avoid massive view bodies
- Follow Apple's Human Interface Guidelines

### Code Organization

- Keep files focused and under 500 lines when possible
- Use `// MARK: -` comments to organize code sections
- Group related functionality together
- Place extensions in separate files when appropriate

### Comments and Documentation

- Add documentation comments (`///`) for public APIs
- Explain **why** not **what** in comments
- Keep comments up-to-date with code changes
- Use TODO/FIXME comments for temporary code

Example:
```swift
/// Schedules an alarm using AlarmKit or falls back to notifications
/// - Parameter alarm: The alarm to schedule
/// - Throws: AlarmError if scheduling fails
/// - Note: Falls back to UserNotifications if AlarmKit is unavailable
func scheduleAlarm(_ alarm: Alarm) async throws {
    // Implementation
}
```

## Project Structure

```
SnoozeIfYouCan/
├── App/                    # App entry point
├── Models/                 # Data models
├── Views/                  # SwiftUI views
├── Services/               # Business logic & managers
├── Design/                 # Theme, components, animations
├── Localization/           # L10n strings
└── Intents/                # App Intents & AlarmKit
```

## Areas for Contribution

### High Priority

- [ ] Unit tests for core business logic
- [ ] UI tests for critical user flows
- [ ] Additional localization (Spanish, French, German, etc.)
- [ ] Accessibility improvements (VoiceOver, Dynamic Type)
- [ ] Performance optimizations

### Medium Priority

- [ ] More alarm sounds and haptic patterns
- [ ] Advanced statistics and data visualization
- [ ] Export data functionality (CSV, JSON)
- [ ] Dark mode refinements
- [ ] Widget improvements

### Low Priority (Future)

- [ ] Multiple charity support
- [ ] Team challenges and leaderboards
- [ ] Health app integration
- [ ] Siri shortcuts

## Testing

### Manual Testing Checklist

Before submitting a PR, please test:

- [ ] Alarm creation and editing
- [ ] Alarm fires at correct time
- [ ] Snooze button works and costs escalate
- [ ] Dismiss button stops alarm
- [ ] Stats update correctly
- [ ] iCloud sync (if applicable)
- [ ] VoiceOver navigation works
- [ ] Works on different device sizes
- [ ] Dark mode displays correctly

### Automated Testing

We use XCTest for unit and UI tests:

```bash
# Run all tests
xcodebuild test -scheme SnoozeIfYouCan -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters
- Reference issues and pull requests liberally

Examples:
```
Add export data functionality to Settings

Fixes #123

- Add CSV export for snooze records
- Add JSON export for statistics
- Update Settings view with export button
```

## Versioning

We use [Semantic Versioning](https://semver.org/):

- **Major**: Breaking changes
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes

## Questions?

Feel free to open an issue with the `question` label or reach out to the maintainers.

## Recognition

Contributors will be recognized in:
- README.md Contributors section
- Release notes for significant contributions
- GitHub's contributor graph

Thank you for contributing to Snooze If You Can! Together, we can make mornings better and support education worldwide. 🌅
