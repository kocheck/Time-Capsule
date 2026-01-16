# Time Capsule

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue.svg" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Swift-5.10+-orange.svg" alt="Swift 5.10+">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT">
</p>

**Time Capsule** is an intelligent macOS menu bar application for task and idea management. It uses AI to suggest the right task at the right time based on context, time of day, and your patterns.

## Features

- **🎯 AI-Powered Suggestions**: Intelligent task ranking using Apple Intelligence or local Ollama
- **⏰ Context-Aware**: Considers time of day, recent completions, and task age
- **🔥 Streak Tracking**: Build momentum with daily completion streaks
- **📊 Progress Analytics**: Track your productivity with detailed statistics
- **🎨 Native macOS UI**: Beautiful SwiftUI interface optimized for the menu bar
- **🔒 Privacy First**: All data stored locally with optional iCloud sync
- **🚀 Focus Mode**: Automatic focus on repeatedly skipped tasks

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16.0+ (for development)
- Swift 5.10+

## Installation

### From Source

```bash
git clone https://github.com/timecapsule/timecapsule.git
cd timecapsule
make setup
make build
make install
```

### Using Xcode

1. Open `TimeCapsule.xcodeproj`
2. Build and run (⌘R)

## Usage

### Quick Start

1. Click the Time Capsule icon in your menu bar
2. Complete the onboarding to configure AI provider
3. **Send Off** tasks you want to work on later
4. Check **Suggestion** tab for AI-recommended tasks
5. Track your progress in the **Progress** tab

### Keyboard Shortcuts

- `⌘⇧T` - Toggle Time Capsule (customizable)

### AI Providers

Time Capsule supports multiple AI providers:

- **Apple Intelligence** (Default): On-device AI for privacy
- **Ollama**: Local LLM via localhost:11434
- **Disabled**: Rule-based suggestions without AI

## Architecture

Time Capsule is built with:

- **SwiftUI** for native macOS UI
- **SwiftData** for persistence
- **MVVM** architecture with `@Observable`
- **Actor-based** context engine for thread safety
- **Modular AI** service architecture

See [Documentation/Architecture.md](Documentation/Architecture.md) for details.

## Development

### Setup

```bash
make setup
```

### Building

```bash
make build
```

### Testing

```bash
make test
```

### Linting

```bash
make lint
```

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](Documentation/Contributing.md) for guidelines.

## License

Time Capsule is available under the MIT License. See [LICENSE](LICENSE) for details.

## Roadmap

- [ ] Calendar integration
- [ ] Siri shortcuts
- [ ] Widgets
- [ ] iOS companion app
- [ ] Team collaboration features

## Support

- **Issues**: [GitHub Issues](https://github.com/timecapsule/timecapsule/issues)
- **Discussions**: [GitHub Discussions](https://github.com/timecapsule/timecapsule/discussions)

## Credits

Built with ❤️ by the Time Capsule team.

---

**Note**: This project uses Apple Intelligence APIs which require macOS 15.0+ for full functionality. On earlier versions, Ollama or rule-based fallback will be used.
