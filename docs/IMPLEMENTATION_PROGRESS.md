# Data Sovereignty Roadmap: Implementation Progress

**Last Updated**: January 2024
**Status**: 3/8 Ideas Implemented ✅
**Branch**: `claude/data-sovereignty-portability-KvNII`

---

## ✅ Completed (Ideas #1-3)

### Idea #1: Export Preview System
**Status**: ✅ COMPLETE
**Commit**: `468121e`
**Files**: ExportPreview.swift, ExportCoordinator.swift, DataPortabilityView.swift

#### What Was Built
- Real-time preview before export
- Live stats: active, completed, archived, total counts
- Date range calculation and formatting
- File size estimation (500 bytes per task average)
- Tag summary with smart truncation (+N more)
- Sample task display with completion status
- Automatic preview refresh on option changes

#### Code Example
```swift
// Generate preview
let coordinator = ExportCoordinator(modelContext: modelContext)
let preview = try await coordinator.generatePreview(options: options)

// Display in UI
ExportPreviewCard(preview: preview)
```

#### User Impact
- **Before**: Blind export, no visibility into what's being exported
- **After**: Full transparency, see exactly what will be exported
- **Result**: Increased trust, reduced anxiety about data operations

---

### Idea #2: Backup Management Dashboard
**Status**: ✅ COMPLETE
**Commit**: `468121e`
**Files**: BackupViewModel.swift, BackupModels.swift, DataPortabilityView.swift

#### What Was Built
- BackupViewModel with state management
- Backup list with metadata (name, age, size, task count)
- Restore functionality with password support
- Delete backups with confirmation
- Refresh button with loading state
- Empty state with helpful messaging
- Encryption status indicators

#### Features
**Backup Row**:
- Visual encryption indicator (lock icon)
- Age formatted as relative time ("2 days ago")
- File size in human-readable format
- Task count badge
- Restore and Delete action buttons

**Restore Sheet**:
- Password input for encrypted backups
- Restore options (clear data, restore settings)
- Warning for destructive operations
- Progress indicator
- Success/error feedback
- Result summary

#### Code Example
```swift
// Load backups
let viewModel = BackupViewModel(modelContext: modelContext)
await viewModel.loadBackups()

// Restore backup
let backupManager = BackupManager(modelContext: modelContext, exportCoordinator: coordinator)
let result = try await backupManager.restoreBackup(
    backup,
    password: "password",
    options: RestoreOptions(clearExistingData: false)
)
```

#### User Impact
- **Before**: Backups created but invisible, no way to restore
- **After**: Full backup lifecycle management
- **Result**: Users actually use backups (expected 60%+ adoption)

---

### Idea #3: Import Conflict Detection
**Status**: ⚡ PARTIAL (Detection done, UI pending)
**Commit**: `468121e`
**Files**: ExportPreview.swift, ImportCoordinator.swift

#### What Was Built
- ImportPreview model with conflict tracking
- generatePreview() method for import preview
- Duplicate title detection algorithm
- ImportConflict model with types (duplicateTitle, sameSourceId, similarContent)
- Conflict counting and reporting

#### Code Example
```swift
// Generate import preview
let coordinator = ImportCoordinator(modelContext: modelContext)
let preview = try await coordinator.generatePreview(from: url, source: .todoist)

if preview.hasConflicts {
    print("Found \(preview.potentialConflicts.count) conflicts")
}
```

#### What's Left
- [ ] UI to display conflicts in ImportSheetView
- [ ] Conflict resolution chooser (Keep, Replace, Merge)
- [ ] Side-by-side diff view
- [ ] Per-conflict resolution
- [ ] "Apply to all" option

#### Implementation Guide
```swift
// Add to ImportSheetView.swift

if let preview = importPreview, preview.hasConflicts {
    ConflictResolutionView(
        conflicts: preview.potentialConflicts,
        onResolve: { resolutions in
            // Apply user's conflict resolutions
            await performImportWithResolutions(resolutions)
        }
    )
}

struct ConflictResolutionView: View {
    let conflicts: [ImportConflict]
    let onResolve: ([ConflictResolution]) -> Void

    var body: some View {
        List(conflicts) { conflict in
            ConflictRow(
                conflict: conflict,
                resolution: $resolutions[conflict.id]
            )
        }
    }
}
```

---

## 🚧 Remaining (Ideas #4-8)

### Idea #4: Menu Bar Quick Actions
**Status**: NOT STARTED
**Priority**: P1 (High user impact, low complexity)
**Estimated Effort**: 2-3 hours

#### Implementation Plan

**Step 1**: Add menu items to AppDelegate

```swift
// AppDelegate.swift

func applicationDidFinishLaunching(_ notification: Notification) {
    setupMenuBar()
}

private func setupMenuBar() {
    if let menu = NSApplication.shared.mainMenu,
       let appMenu = menu.items.first {

        // Add Data Portability submenu
        let dataMenu = NSMenu(title: "Data")

        let quickExport = NSMenuItem(
            title: "Quick Export (JSON)",
            action: #selector(performQuickExport),
            keyEquivalent: "e"
        )
        quickExport.keyEquivalentModifierMask = [.command, .shift]
        dataMenu.addItem(quickExport)

        let quickBackup = NSMenuItem(
            title: "Create Backup Now",
            action: #selector(performQuickBackup),
            keyEquivalent: "b"
        )
        quickBackup.keyEquivalentModifierMask = [.command, .shift]
        dataMenu.addItem(quickBackup)

        dataMenu.addItem(.separator())

        let manageData = NSMenuItem(
            title: "Manage Data...",
            action: #selector(showDataPortability),
            keyEquivalent: ""
        )
        dataMenu.addItem(manageData)

        menu.addItem(withTitle: "Data", action: nil, keyEquivalent: "")
            .submenu = dataMenu
    }
}

@objc func performQuickExport() {
    Task {
        let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            .appendingPathComponent("TimeCapsule-Quick-Export-\(Date().ISO8601Format()).json")

        // Perform export to Downloads
        // Show notification when complete
    }
}
```

**Step 2**: Add status indicator

```swift
// Show last backup date in menu
let statusItem = NSMenuItem(title: "Last backup: \(lastBackupDate)", action: nil, keyEquivalent: "")
statusItem.isEnabled = false
dataMenu.addItem(statusItem)
```

**Expected Result**:
- Right-click menu bar → Data → Quick Export
- Keyboard shortcut: ⌘⇧E for export, ⌘⇧B for backup
- Downloads folder gets "TimeCapsule-Quick-Export-2024-01-15.json"
- Notification: "Exported 145 tasks to Downloads"

---

### Idea #5: Progressive Streaming Export
**Status**: NOT STARTED
**Priority**: P3 (Nice to have, high complexity)
**Estimated Effort**: 6-8 hours

#### Implementation Plan

**Step 1**: Create StreamingExporter

```swift
@Observable
class StreamingExporter {
    var progress: Double = 0.0
    var currentOperation: String = ""
    var estimatedTimeRemaining: String?
    var isCancelled = false

    func export(
        tasks: [TaskItem],
        to destination: URL,
        format: ExportFormat
    ) async throws {
        let total = tasks.count
        var exported = 0

        for task in tasks {
            guard !isCancelled else {
                throw ExportError.cancelled
            }

            // Export task
            await exportTask(task, to: destination, format: format)

            exported += 1
            progress = Double(exported) / Double(total)
            currentOperation = "Exporting task \(exported)/\(total)..."

            // Estimate remaining time
            let elapsed = Date().timeIntervalSince(startTime)
            let rate = Double(exported) / elapsed
            let remaining = Double(total - exported) / rate
            estimatedTimeRemaining = formatDuration(remaining)
        }
    }
}
```

**Step 2**: Add progress UI

```swift
if isExporting {
    ExportProgressView(exporter: streamingExporter)
}
```

**When to Use**: Only show progress for exports > 100 tasks

---

### Idea #6: Plugin Architecture
**Status**: NOT STARTED
**Priority**: P2 (Developer experience)
**Estimated Effort**: 8-10 hours

#### Implementation Plan

**Step 1**: Define plugin protocols

```swift
// ExportFormatPlugin.swift
protocol ExportFormatPlugin {
    var identifier: String { get }
    var name: String { get }
    var fileExtension: String { get }
    var description: String { get }

    func export(data: ExportableData) async throws -> Data
}

// Built-in plugins
class JSONExportPlugin: ExportFormatPlugin {
    let identifier = "com.timecapsule.export.json"
    let name = "JSON"
    let fileExtension = "json"
    let description = "Standard JSON format"

    func export(data: ExportableData) async throws -> Data {
        // Implementation
    }
}
```

**Step 2**: Create plugin registry

```swift
class ExportPluginRegistry {
    static let shared = ExportPluginRegistry()
    private var plugins: [String: ExportFormatPlugin] = [:]

    func register(_ plugin: ExportFormatPlugin) {
        plugins[plugin.identifier] = plugin
    }

    func allPlugins() -> [ExportFormatPlugin] {
        Array(plugins.values)
    }
}
```

**Step 3**: Update UI to use plugins

```swift
// ExportSheetView.swift
let plugins = ExportPluginRegistry.shared.allPlugins()

Picker("Format", selection: $selectedPluginID) {
    ForEach(plugins, id: \.identifier) { plugin in
        Label(plugin.name, systemImage: plugin.icon)
            .tag(plugin.identifier)
    }
}
```

**Benefits**:
- Add PDF export without touching core code
- Third-party developers can create plugins
- A/B test new formats easily

---

### Idea #7: Logging & Diagnostics System
**Status**: NOT STARTED
**Priority**: P1 (Debugging, support)
**Estimated Effort**: 4-5 hours

#### Implementation Plan

**Step 1**: Create logger actor

```swift
actor DataSovereigntyLogger {
    private var logs: [LogEntry] = []
    private let maxLogs = 1000

    struct LogEntry: Codable {
        let timestamp: Date
        let level: LogLevel
        let category: String
        let message: String
        let metadata: [String: String]
    }

    func log(level: LogLevel, category: String, message: String, metadata: [String: String] = [:]) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            metadata: metadata
        )

        logs.append(entry)

        // Trim old logs
        if logs.count > maxLogs {
            logs.removeFirst(logs.count - maxLogs)
        }
    }

    func exportDiagnostics() async throws -> URL {
        let bundle = DiagnosticBundle(
            logs: logs,
            systemInfo: SystemInfo.current,
            timestamp: Date()
        )

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TimeCapsule-Diagnostics-\(Date().ISO8601Format()).json")

        let data = try JSONEncoder.prettyPrinted.encode(bundle)
        try data.write(to: url)

        return url
    }
}
```

**Step 2**: Add to coordinators

```swift
// ExportCoordinator.swift
private let logger = DataSovereigntyLogger.shared

func export(...) async throws {
    await logger.log(
        level: .info,
        category: "Export",
        message: "Starting export",
        metadata: [
            "format": format.rawValue,
            "taskCount": "\(tasks.count)"
        ]
    )

    // ... export logic

    if let error = error {
        await logger.log(
            level: .error,
            category: "Export",
            message: "Export failed",
            metadata: [
                "error": error.localizedDescription,
                "format": format.rawValue
            ]
        )
    }
}
```

**Step 3**: Add export button in Settings

```swift
Button("Export Diagnostics") {
    Task {
        let url = try await DataSovereigntyLogger.shared.exportDiagnostics()
        // Show share sheet
    }
}
```

---

### Idea #8: Integration Tests with Sample Data
**Status**: NOT STARTED
**Priority**: P1 (Quality assurance)
**Estimated Effort**: 6-8 hours

#### Implementation Plan

**Step 1**: Create sample data generator

```swift
// SampleDataGenerator.swift
class SampleDataGenerator {
    static func generateRealisticDataset(count: Int = 100) -> [TaskItem] {
        var tasks: [TaskItem] = []

        let templates = [
            ("Review weekly reports", ["work", "management"], .high),
            ("Buy groceries", ["personal", "errands"], .normal),
            ("Read research paper", ["learning"], .normal),
            ("Plan team meeting", ["work"], .high),
            ("Call dentist", ["personal", "health"], .low),
            ("Debug production issue", ["work", "urgent"], .high),
            ("Write blog post", ["personal", "writing"], .normal),
        ]

        for i in 0..<count {
            let template = templates[i % templates.count]
            let task = TaskItem(
                title: "\(template.0) #\(i)",
                tags: template.1,
                priority: template.2
            )

            // Realistic dates
            task.createdAt = Date().addingTimeInterval(-Double(i) * 86400)

            // Some completed
            if i % 3 == 0 {
                task.completedAt = task.createdAt.addingTimeInterval(Double.random(in: 3600...86400))
            }

            // Some skipped
            task.skipCount = Int.random(in: 0...5)

            tasks.append(task)
        }

        return tasks
    }
}
```

**Step 2**: Write integration tests

```swift
// DataSovereigntyIntegrationTests.swift

@Test("Export and import 1000 tasks preserves all data")
func largeDatasetRoundTrip() async throws {
    // Generate data
    let tasks = SampleDataGenerator.generateRealisticDataset(count: 1000)
    for task in tasks {
        context.insert(task)
    }
    try context.save()

    // Export
    let coordinator = ExportCoordinator(modelContext: context)
    let result = try await coordinator.export(
        format: .universalTaskFormat,
        options: .complete,
        destination: tempURL
    )

    // Clear database
    try context.delete(model: TaskItem.self)

    // Import
    let importCoordinator = ImportCoordinator(modelContext: context)
    let importResult = try await importCoordinator.importData(
        from: result.destination,
        source: .universalTaskFormat,
        options: .init()
    )

    // Verify
    #expect(importResult.importedCount == 1000)

    let importedTasks = try context.fetch(FetchDescriptor<TaskItem>())
    #expect(importedTasks.count == 1000)
}

@Test("Handles special characters correctly")
func specialCharactersRoundTrip() async throws {
    let task = TaskItem(
        title: "Test 你好 🎉 emoji & special «chars»",
        tags: ["français", "日本語"],
        priority: .high
    )

    // Export/Import cycle
    // Verify all characters preserved
}

@Test("Handles very long text fields")
func longTextRoundTrip() async throws {
    let longDescription = String(repeating: "Lorem ipsum ", count: 1000)
    let task = TaskItem(
        title: "Long text task",
        description: longDescription,
        tags: [],
        priority: .normal
    )

    // Export/Import cycle
    // Verify text not truncated
}
```

---

## 📊 Progress Summary

| Idea | Priority | Status | Effort | Completion |
|------|----------|--------|--------|------------|
| #1 Export Preview | P0 | ✅ | 3h | 100% |
| #2 Backup Dashboard | P0 | ✅ | 5h | 100% |
| #3 Conflict Resolution | P1 | ⚡ | 6h | 40% |
| #4 Menu Bar Actions | P1 | ⬜ | 3h | 0% |
| #5 Streaming Export | P3 | ⬜ | 8h | 0% |
| #6 Plugin Architecture | P2 | ⬜ | 10h | 0% |
| #7 Logging System | P1 | ⬜ | 5h | 0% |
| #8 Integration Tests | P1 | ⬜ | 8h | 0% |

**Total Effort**: 48 hours
**Completed**: 8 hours (17%)
**Remaining**: 40 hours (83%)

---

## 🎯 Recommended Next Steps

### This Week (8-10 hours)
1. **Complete #3**: Add conflict resolution UI (2h)
2. **Implement #4**: Menu bar quick actions (3h)
3. **Implement #7**: Logging & diagnostics (5h)

### Next Week (8-10 hours)
4. **Implement #8**: Integration tests (8h)

### Later (20+ hours)
5. **Implement #6**: Plugin architecture (10h)
6. **Implement #5**: Streaming export (8h) - Only if needed

---

## 🔧 Development Tips

### Testing Changes
```bash
# Build and run
xcodebuild -project TimeCapsule.xcodeproj -scheme TimeCapsule

# Run tests
swift test

# Test export
# 1. Create some tasks in the app
# 2. Settings → Manage Data → Export
# 3. Verify preview shows correct counts
# 4. Export and verify file contents

# Test backup
# 1. Settings → Manage Data → Backup
# 2. Create encrypted backup
# 3. Verify backup appears in list
# 4. Test restore with wrong password (should fail)
# 5. Test restore with correct password (should succeed)
```

### Code Style
- Use `@Observable` for ViewModels
- Use `actor` for coordinators (thread safety)
- Always provide `@MainActor` for UI operations
- Use `.task {}` for async initialization
- Provide loading states for async operations
- Use `defer` for cleanup

### UI Patterns
```swift
// Loading state
if isLoading {
    ProgressView()
} else {
    ContentView()
}

// Error state
if let error = error {
    ErrorView(error: error)
}

// Success state
if let result = result {
    SuccessView(result: result)
}
```

---

## 📖 Documentation

All documentation is in `/docs/`:
- `DATA_SOVEREIGNTY.md` - User-facing guide
- `DATA_SOVEREIGNTY_ROADMAP.md` - All 10 ideas with mockups
- `IMPLEMENTATION_PROGRESS.md` - This document

Keep docs updated as features are completed!

---

**Questions?** Check the roadmap document or review the implemented code for patterns.

**Good luck!** 🚀
