# Time Capsule Linter Context Document

> **Purpose**: This living document provides context for AI assistants, new team members, and automated tools about our linting strategy, rules, and rationale.

**Last Updated**: 2026-01-16
**Maintainer**: Time Capsule Team
**SwiftLint Version**: 0.54.0+

---

## Table of Contents

1. [Philosophy](#philosophy)
2. [Rule Categories](#rule-categories)
3. [Security Rules Explained](#security-rules-explained)
4. [Data Safety Rules Explained](#data-safety-rules-explained)
5. [When to Disable Rules](#when-to-disable-rules)
6. [Adding New Rules](#adding-new-rules)
7. [Common Fixes](#common-fixes)
8. [Rule Change Log](#rule-change-log)

---

## Philosophy

Time Capsule handles **personal user data** (tasks, ideas, notes). Our linting strategy prioritizes:

### 1. Data Safety First
- User data must never be lost, corrupted, or leaked
- All storage operations must have error handling
- No silent failures allowed

### 2. Security by Default
- No hardcoded secrets
- No unencrypted sensitive storage
- HTTPS everywhere
- Logging must not expose user data

### 3. Crash Prevention
- No force unwrapping in production code
- No force try
- No force cast
- Proper error handling required

### 4. Maintainability
- Consistent code style
- Required documentation for public APIs
- Clear code organization with MARK comments

---

## Rule Categories

### 🔴 Error (Must Fix)

These rules produce **errors** and block merging:

| Rule | Rationale |
|------|-----------|
| `force_unwrapping` | Crashes app, loses user data |
| `force_try` | Crashes app on error |
| `force_cast` | Crashes app on type mismatch |
| `no_empty_catch` | Hides errors, causes silent data loss |
| `no_print_statements` | Leaks data to device logs |
| `no_hardcoded_secrets` | Security vulnerability |
| `no_unencrypted_storage` | Sensitive data exposure |
| `no_http_urls` | Man-in-the-middle attacks |

### 🟡 Warning (Should Fix)

These rules produce **warnings** and should be fixed before merge:

| Rule | Rationale |
|------|-----------|
| `line_length > 110` | Readability |
| `cyclomatic_complexity > 8` | Maintainability |
| `no_direct_userdefaults` | Use AppSettings for consistency |
| `todo_with_tracking` | TODOs need issue numbers |

---

## Security Rules Explained

### `no_hardcoded_secrets`
```swift
// ❌ BAD
let apiKey = "sk-1234567890abcdef"

// ✅ GOOD
let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? ""
// Or use KeychainService
let apiKey = try KeychainService.shared.get("api_key")
```

### `no_unencrypted_storage`
```swift
// ❌ BAD - Never store sensitive data in UserDefaults
UserDefaults.standard.set(password, forKey: "password")

// ✅ GOOD - Use Keychain
try KeychainService.shared.set(password, for: "password")
```

### `no_print_statements`
```swift
// ❌ BAD - Leaks to Console.app and device logs
print("User created task: \(task.title)")

// ✅ GOOD - Use Logger with privacy controls
Logger.data.info("Task created", metadata: ["id": task.id.uuidString])

// For sensitive data, use redaction:
Logger.data.info("Task: \(task.title, privacy: .private)")
```

### `no_http_urls`
```swift
// ❌ BAD - Insecure
let url = URL(string: "http://api.example.com/data")

// ✅ GOOD - Always HTTPS
let url = URL(string: "https://api.example.com/data")

// Exception: localhost for development
let url = URL(string: "http://localhost:11434") // Ollama - OK
```

---

## Data Safety Rules Explained

### `no_empty_catch`
```swift
// ❌ BAD - Silent failure, data might not save
do {
    try modelContext.save()
} catch {
    // Empty - user thinks data saved but it didn't!
}

// ✅ GOOD - Log and handle
do {
    try modelContext.save()
} catch {
    Logger.data.error("Failed to save: \(error.localizedDescription)")
    throw DataError.saveFailed(underlying: error)
}
```

### `no_force_unwrapping`
```swift
// ❌ BAD - Crashes if nil
let task = tasks.first!

// ✅ GOOD - Safe handling
guard let task = tasks.first else {
    Logger.app.warning("No tasks available")
    return
}

// ✅ ALSO GOOD - With default
let task = tasks.first ?? TaskItem.placeholder
```

---

## When to Disable Rules

### Legitimate Disable Cases

```swift
// 1. Test files - force unwrap is acceptable
// swiftlint:disable force_unwrapping
let result = try! sut.process(data)
// swiftlint:enable force_unwrapping

// 2. Preview providers
// swiftlint:disable:next force_try
static var preview = try! ModelContainer(for: TaskItem.self)

// 3. Truly impossible states (document why!)
// swiftlint:disable:next force_unwrapping
// Force unwrap safe: URL is compile-time constant
let url = URL(string: "https://timecapsule.app")!
```

### Never Disable These Rules

- `no_hardcoded_secrets` - No exceptions
- `no_empty_catch` - Always handle errors
- `no_print_statements` - Use Logger instead

### Disable Comment Format

Always include a reason:
```swift
// swiftlint:disable:next force_unwrapping - Safe: validated above on line 42
```

---

## Adding New Rules

### Process

1. **Propose** - Create GitHub issue with rule proposal
2. **Discuss** - Team reviews rationale and impact
3. **Test** - Run against codebase to measure impact
4. **Document** - Update this file with explanation
5. **Implement** - Add to `.swiftlint.yml`
6. **Communicate** - Announce in team channel

### New Rule Template

```yaml
# Add to custom_rules section
rule_name:
  name: "Human Readable Name"
  regex: "pattern_to_match"
  message: "Why this is bad and how to fix it"
  severity: warning  # or error
  excluded:
    - ".*Tests?\\.swift$"  # if not applicable to tests
```

---

## Common Fixes

### Fix: Line too long

```swift
// ❌ Before (140 characters)
let result = someObject.performVeryLongOperation(withParameter: firstParameter, andAnotherParameter: secondParameter, andYetAnother: third)

// ✅ After (split across lines)
let result = someObject.performVeryLongOperation(
    withParameter: firstParameter,
    andAnotherParameter: secondParameter,
    andYetAnother: third
)
```

### Fix: Cyclomatic complexity too high

```swift
// ❌ Before (complexity: 12)
func processTask(_ task: TaskItem) {
    if task.isCompleted {
        if task.priority == .high {
            // ...
        } else if task.priority == .normal {
            // ...
        }
    } else {
        if task.isStale {
            // ...
        }
    }
}

// ✅ After (split into focused functions)
func processTask(_ task: TaskItem) {
    task.isCompleted ? handleCompleted(task) : handlePending(task)
}

private func handleCompleted(_ task: TaskItem) {
    switch task.priority {
    case .high: handleHighPriority(task)
    case .normal: handleNormalPriority(task)
    case .low: handleLowPriority(task)
    }
}
```

---

## Rule Change Log

| Date | Change | Rationale | PR |
|------|--------|-----------|-----|
| 2026-01-16 | Initial security-focused configuration | Enhanced data safety | #2 |
| | Added comprehensive custom rules | Security-first approach | |
| | Set complexity warning to 8 | Maintain readability | |

---

## Integration with AI Assistants

When working with AI coding assistants (Claude, Copilot), reference this document:

```
@context Documentation/LINTER_CONTEXT.md

Please fix the SwiftLint violations in TaskViewModel.swift
```

The AI should:
1. Understand our security-first philosophy
2. Know which rules are errors vs warnings
3. Apply fixes that match our patterns
4. Not suggest disabling critical security rules

---

## Metrics & Goals

### Current Targets

| Metric | Target | Current |
|--------|--------|---------|
| Error violations | 0 | - |
| Warning violations | < 50 | - |
| Test coverage | > 80% | - |

### Tracking

Run weekly:
```bash
./Scripts/lint.sh --report
# Generates lint-report.html with trends
```

---

## Questions?

- **GitHub**: Open an issue with `[Linter]` prefix
- **Documentation**: See `.swiftlint.yml` for full config
