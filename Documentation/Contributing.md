# Contributing to Time Capsule

Thank you for your interest in contributing to Time Capsule! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Be respectful, inclusive, and constructive in all interactions.

## Getting Started

### Prerequisites

- macOS 14.0+
- Xcode 16.0+
- Git
- Homebrew (for development tools)

### Setup

1. **Fork and Clone:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/timecapsule.git
   cd timecapsule
   ```

2. **Install Dependencies:**
   ```bash
   make setup
   ```

3. **Build the Project:**
   ```bash
   make build
   ```

4. **Run Tests:**
   ```bash
   make test
   ```

## Development Workflow

### Creating a Branch

```bash
git checkout -b feature/your-feature-name
```

**Branch Naming:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions/updates

### Making Changes

1. **Follow Swift Style Guide:**
   - Use SwiftLint (automatic on build)
   - Follow Apple's API Design Guidelines
   - Write clear, self-documenting code

2. **Write Tests:**
   - Add unit tests for new functionality
   - Maintain or improve code coverage
   - Test edge cases

3. **Update Documentation:**
   - Update inline documentation
   - Update README if needed
   - Add architecture notes for significant changes

### Committing Changes

**Commit Message Format:**
```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

**Example:**
```
feat: add calendar integration

Implement calendar view showing tasks by date with
filtering and grouping capabilities.

Closes #123
```

### Submitting a Pull Request

1. **Push Your Branch:**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request:**
   - Use the PR template
   - Link related issues
   - Add screenshots for UI changes
   - Request reviews

3. **Address Feedback:**
   - Respond to review comments
   - Make requested changes
   - Push updates to the same branch

## Code Style

### Swift Guidelines

- Use Swift's modern features (async/await, @Observable, etc.)
- Prefer immutability when possible
- Use meaningful variable names
- Keep functions focused and short
- Document complex logic

### SwiftUI Best Practices

- Use `@Observable` over `@ObservableObject`
- Extract reusable components
- Keep views simple and focused
- Use proper preview providers

### Testing Guidelines

- Write clear test names
- Use `#expect` for assertions
- Test both success and failure cases
- Mock external dependencies

## Project-Specific Guidelines

### Adding AI Providers

1. Implement `AIServiceProtocol`
2. Add to `AIServiceFactory`
3. Update settings view
4. Add tests
5. Document integration

### Adding Views

1. Create view in appropriate directory
2. Create corresponding ViewModel if needed
3. Add to navigation structure
4. Add preview provider
5. Write UI tests

### Modifying Data Models

1. Consider migration path
2. Update all affected services
3. Add/update tests
4. Document schema changes

## Testing

### Running Tests

```bash
# All tests
make test

# Specific test
xcodebuild test -scheme TimeCapsule -only-testing:TimeCapsuleTests/TaskItemTests
```

### Writing Tests

```swift
import Testing
@testable import TimeCapsule

@Suite("Feature Tests")
struct FeatureTests {
    @Test("Test description")
    func testSomething() {
        #expect(condition)
    }
}
```

## Documentation

### Code Documentation

Use Swift's documentation comments:

```swift
/// Brief description
///
/// Detailed explanation of what this does.
///
/// - Parameters:
///   - param1: Description
///   - param2: Description
/// - Returns: Description
/// - Throws: Description of errors
func doSomething(param1: String, param2: Int) throws -> Bool {
    // Implementation
}
```

### Architecture Documentation

Update `Documentation/Architecture.md` for:
- New major components
- Architectural decisions
- Integration patterns

## Getting Help

- **Questions**: Open a [Discussion](https://github.com/timecapsule/timecapsule/discussions)
- **Bugs**: File an [Issue](https://github.com/timecapsule/timecapsule/issues)
- **Chat**: Join our Discord (link in README)

## Recognition

Contributors will be:
- Listed in release notes
- Added to CONTRIBUTORS.md
- Credited in the app's About section

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Time Capsule! 🎉
