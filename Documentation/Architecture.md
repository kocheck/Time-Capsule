# Time Capsule Architecture

## Overview

Time Capsule is built with a modern Swift architecture leveraging the latest macOS technologies for a native, performant experience.

## Technology Stack

- **Language**: Swift 5.10+
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Architecture Pattern**: MVVM with `@Observable`
- **Concurrency**: Swift Concurrency (async/await, actors)
- **Minimum macOS**: 14.0 (Sonoma)

## Project Structure

```
TimeCapsule/
├── App/                    # Application entry point
├── Models/                 # Data models (SwiftData)
├── Views/                  # SwiftUI views and components
├── ViewModels/             # Observable view models
├── Services/               # Business logic and services
│   ├── AI/                 # AI service implementations
│   ├── ContextEngine.swift # Task ranking logic
│   ├── DataService.swift   # Data management
│   ├── StatsService.swift  # Statistics tracking
│   └── ...
├── Utilities/              # Helpers and extensions
└── Resources/              # Assets and configuration
```

## Core Components

### 1. Data Layer

**SwiftData Models:**
- `TaskItem`: Core task entity with metadata
- `DailyStats`: Daily activity tracking
- `AppSettings`: User preferences

**Features:**
- Automatic persistence
- Optional iCloud sync
- Thread-safe with model actors

### 2. Service Layer

**AI Services:**
- `AIServiceProtocol`: Abstraction for AI providers
- `AppleIntelligenceService`: On-device AI
- `OllamaService`: Local LLM integration
- `DisabledAIService`: Rule-based fallback

**Context Engine:**
- Actor-based for thread safety
- Analyzes task context (time, tags, history)
- Provides intelligent task ranking

**Data Services:**
- `DataService`: Settings and data management
- `StatsService`: Analytics and streak calculation
- `NotificationService`: System notifications
- `KeyboardShortcutService`: Global hotkey support

### 3. View Layer

**Architecture:**
- MVVM pattern with `@Observable` macro
- Unidirectional data flow
- Composition over inheritance

**Main Views:**
- `MenuBarView`: Container for tab navigation
- `SendOffView`: Task creation
- `TaskSuggestionView`: AI-powered recommendations
- `DailyProgressView`: Statistics and streaks
- `SettingsView`: Configuration

**Reusable Components:**
- `TaskCard`: Task display
- `TagChip`: Tag visualization
- `FlowLayout`: Tag wrapping layout
- `ActionButton`: Styled buttons
- `StreakBadge`: Gamification element

### 4. ViewModel Layer

**Observable ViewModels:**
- `TaskViewModel`: CRUD operations
- `SuggestionViewModel`: Suggestion logic
- `StatsViewModel`: Analytics display
- `SettingsViewModel`: Settings management

**Benefits:**
- Automatic UI updates with `@Observable`
- Clear separation of concerns
- Testable business logic

## Data Flow

```
User Action → View
    ↓
ViewModel (validates, transforms)
    ↓
Service (business logic)
    ↓
Model (SwiftData)
    ↓
Persistence Layer
    ↓
Automatic UI Update via @Observable
```

## AI Integration

### Task Ranking Algorithm

1. **Context Collection:**
   - Current time and day
   - Recently completed tasks
   - User's skip patterns

2. **AI Analysis:**
   - Apple Intelligence: On-device processing
   - Ollama: Local LLM inference
   - Fallback: Rule-based scoring

3. **Scoring Factors:**
   - Priority weight (high > normal > low)
   - Age (older tasks score higher)
   - Skip penalty (frequently skipped = lower score)
   - Time-based bonuses (morning/evening preferences)
   - Tag momentum (related to recent completions)

### Privacy & Performance

- **Apple Intelligence**: Zero data leaves device
- **Ollama**: All processing on localhost
- **No Cloud Dependencies**: Works offline
- **Fast Inference**: < 2s response time

## Testing Strategy

### Unit Tests
- Model logic validation
- Service behavior verification
- ViewModel state management

### Integration Tests
- Service interactions
- Data flow validation
- AI service integration

### UI Tests
- Critical user flows
- Onboarding experience
- Task lifecycle

## Performance Considerations

- **Lazy Loading**: Views load data on demand
- **Actor Isolation**: Thread-safe concurrency
- **Efficient Queries**: Optimized SwiftData fetch descriptors
- **Memory Management**: Weak references, proper cleanup

## Security

- **Sandbox**: Full macOS App Sandbox compliance
- **Hardened Runtime**: Enhanced security features
- **Notarization**: Apple notarized distribution
- **Local-First**: No sensitive data transmission

## Future Enhancements

- [ ] CloudKit sync for multi-device
- [ ] Siri integration
- [ ] WidgetKit support
- [ ] iOS companion app
- [ ] More AI providers (OpenAI, Anthropic)

## Build Process

```bash
# Development
make build

# Testing
make test

# Linting
make lint

# Release
make archive
```

## Dependencies

- **System Frameworks Only**: No third-party dependencies
- **Pure Swift**: 100% Swift codebase
- **Modern APIs**: Leverages latest macOS features

---

For implementation details, see the inline code documentation.
