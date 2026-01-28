# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

**Note**: This project is currently archived. Security updates will be limited to critical issues only.

## Reporting a Vulnerability

If you discover a security vulnerability in Snooze If You Can, please report it responsibly:

### How to Report

1. **Do NOT** open a public GitHub issue for security vulnerabilities
2. Email the maintainer directly at: [contact@hmddevs.org]
3. Include the following information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity
  - Critical: Within 7 days
  - High: Within 30 days
  - Medium/Low: Best effort

### Scope

#### In Scope

- Authentication bypass
- Data exposure (user alarm data, donation history)
- StoreKit payment vulnerabilities
- CloudKit data leaks
- Injection attacks (if applicable)
- Privilege escalation
- Code execution vulnerabilities

#### Out of Scope

- Vulnerabilities in third-party dependencies (report to upstream)
- AlarmKit framework bugs (report to Apple via Feedback Assistant)
- Social engineering attacks
- Physical device access attacks
- Denial of service (the app is single-user)
- Issues in archived/outdated versions

## Security Considerations

### Data Storage

- **UserDefaults**: Used for non-sensitive app preferences and alarm data
  - No encryption applied (iOS sandboxing provides isolation)
  - Data includes alarm times, labels, snooze counts
  - No passwords or payment information stored

- **CloudKit**: Used for iCloud sync
  - End-to-end encrypted by Apple
  - Data only accessible to the user's iCloud account
  - Follows Apple's CloudKit security model

- **Keychain**: Not currently used
  - Future enhancement for sensitive settings

### Payment Security

- **StoreKit 2**: All payment processing handled by Apple
  - No credit card information stored or processed by the app
  - Transaction verification performed client-side
  - Server-side verification not implemented (should be added for production)

### Network Security

- **No Custom Networking**: App does not make custom HTTP requests
- **Apple Services Only**: CloudKit and StoreKit use Apple's secure protocols
- **Certificate Pinning**: Not applicable (no custom servers)

### Authentication

- **No User Accounts**: App is single-user, no authentication required
- **iCloud**: Authentication handled by iOS/iPadOS system

### Privacy

See [Privacy Policy](#privacy-policy-considerations) section below.

## Known Security Limitations

### 1. Client-Side Payment Verification

**Issue**: StoreKit transactions are verified client-side only.

**Risk**: Sophisticated attackers could potentially bypass payment checks.

**Mitigation**: For production, implement server-side receipt verification.

**Status**: Open (waiting for server infrastructure)

### 2. Local Data Storage

**Issue**: Alarm data and statistics stored in UserDefaults without encryption.

**Risk**: Physical device access could allow reading alarm data.

**Mitigation**: iOS sandboxing prevents other apps from accessing this data. For sensitive deployments, consider Keychain storage with Data Protection.

**Status**: Accepted risk (alarm times are not typically sensitive)

### 3. No Server-Side Validation

**Issue**: All business logic runs client-side.

**Risk**: Users could potentially modify app behavior via jailbreaking or reverse engineering.

**Mitigation**: Not a critical risk for this use case. Primarily affects the user's own experience and local donation tracking.

**Status**: Accepted risk (no multiplayer or competitive features)

## Privacy Policy Considerations

When publishing to the App Store, ensure your Privacy Policy covers:

- **Data Collection**: What data is collected (alarm times, snooze records, statistics)
- **Data Storage**: Where data is stored (device, iCloud)
- **Data Sharing**: No data shared with third parties
- **User Rights**: How users can export or delete their data
- **Children's Privacy**: COPPA compliance if applicable
- **Contact Information**: How users can contact you about privacy

## Recommended Security Practices for Contributors

### Code Reviews

- All pull requests require review before merging
- Security-critical changes require additional scrutiny
- Use GitHub's security advisories for vulnerability tracking

### Dependencies

- Minimize third-party dependencies
- Keep dependencies updated
- Monitor GitHub Dependabot alerts
- Audit dependencies before adding them

### Secrets Management

- Never commit API keys, tokens, or credentials
- Use Xcode's User-Defined Settings for sensitive values
- Add secrets files to .gitignore
- Use environment variables for local development

### Code Signing

- Use proper Apple Developer certificates
- Enable App Transport Security (ATS)
- Follow Apple's code signing best practices
- Protect provisioning profiles and certificates

### Testing

- Test with realistic data volumes
- Test edge cases and error conditions
- Perform penetration testing before major releases
- Use Xcode's Memory Debugger and Instruments

## Compliance

### GDPR (EU)

- Users have right to access their data (export feature)
- Users have right to deletion (uninstall removes data)
- No data processing without consent (onboarding flow)
- Data minimization (only collect what's necessary)

### CCPA (California)

- Disclose data collection in Privacy Policy
- Provide data export mechanism
- Honor deletion requests
- No sale of personal information

### App Store Guidelines

- Comply with Apple's App Store Review Guidelines
- Follow Data Collection and Storage requirements
- Implement Privacy Policy
- Respect Critical Alert permissions (do not abuse)

## Security Checklist for Release

Before releasing to production:

- [ ] Privacy Policy created and linked in app
- [ ] All secrets removed from code
- [ ] StoreKit server-side verification implemented
- [ ] CloudKit permissions configured correctly
- [ ] Certificate pinning (if custom backend added)
- [ ] Code obfuscation considered
- [ ] Security audit performed
- [ ] Penetration testing completed
- [ ] App Store security questionnaire filled out
- [ ] GDPR compliance verified
- [ ] Data export functionality tested
- [ ] Crash reporting configured (with PII redaction)

## Contact

For security concerns, contact:
- Email: contact@hmddevs.org
- GitHub: [@ichbinheimdall](https://github.com/ichbinheimdall)
- Response Time: 48 hours

---

**Last Updated**: January 28, 2026  
**Next Review**: Upon un-archiving project
