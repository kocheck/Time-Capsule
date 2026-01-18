# Data Sovereignty & Portability

Time Capsule is built on a **"Your Data, Your Control"** philosophy. This document explains how we ensure you maintain complete ownership and control over your data.

## Core Principles

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DATA SOVEREIGNTY PRINCIPLES                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. LOCAL-FIRST        All data stored on device by default                 │
│  2. EXPORTABLE         Full data export in open formats (JSON, CSV, etc.)   │
│  3. IMPORTABLE         Accept data from other productivity tools            │
│  4. DELETABLE          True deletion, not soft-delete. User controls data   │
│  5. TRANSPARENT        User can inspect all data we store about them        │
│  6. PORTABLE           Move data between devices without cloud dependency   │
│  7. INTEROPERABLE      Standard formats that work with other tools          │
│                                                                              │
│  "If you can't export it, you don't own it."                                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Universal Task Format (UTF)

Time Capsule uses an open, versioned data format called **Universal Task Format (UTF)**.

### Format Specifications

- **Format Identifier**: `com.timecapsule.utf`
- **Current Version**: `1.0.0`
- **Encoding**: JSON (UTF-8)
- **Date Format**: ISO 8601
- **Integrity**: SHA-256 checksums

### UTF Structure

```json
{
  "formatVersion": "1.0.0",
  "formatIdentifier": "com.timecapsule.utf",
  "exportedAt": "2024-01-15T10:30:00Z",
  "exportedFrom": {
    "appName": "Time Capsule",
    "appVersion": "1.0.0",
    "platform": "macOS",
    "platformVersion": "14.0"
  },
  "checksum": "sha256-hash-of-content",
  "tasks": [...],
  "completedTasks": [...],
  "archivedTasks": [...],
  "settings": {...},
  "schema": {...}
}
```

### Task Schema

Each task in UTF contains:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string (UUID) | ✅ | Unique identifier |
| `title` | string | ✅ | Task title |
| `description` | string | ❌ | Detailed description |
| `tags` | [string] | ❌ | Categorization tags |
| `priority` | enum | ✅ | low, normal, high |
| `createdAt` | datetime | ✅ | Creation timestamp |
| `completedAt` | datetime | ❌ | Completion timestamp |
| `skipCount` | integer | ✅ | Times skipped |
| `dailySkipCount` | integer | ✅ | Daily skip count |
| `isArchived` | boolean | ✅ | Archive status |
| `contextHints` | [string] | ❌ | AI-generated hints |

## Export Formats

Time Capsule supports multiple export formats for different use cases:

### 1. Universal Task Format (UTF)
- **Best for**: Backup, migration, long-term storage
- **Format**: JSON
- **Includes**: Everything (tasks, settings, metadata)
- **Advantage**: Complete data preservation
- **File extension**: `.utf.json`

### 2. JSON
- **Best for**: Developers, data analysis, integration
- **Format**: Standard JSON
- **Includes**: Tasks and basic metadata
- **Advantage**: Easy to parse programmatically
- **File extension**: `.json`

### 3. CSV
- **Best for**: Spreadsheets, reporting, data analysis
- **Format**: Comma-separated values
- **Includes**: All task fields
- **Advantage**: Open in Excel, Numbers, Google Sheets
- **File extension**: `.csv`

### 4. Markdown
- **Best for**: Documentation, printing, human reading
- **Format**: GitHub-flavored Markdown
- **Includes**: Tasks with formatting
- **Advantage**: Beautiful, readable output
- **File extension**: `.md`

## Import Sources

Time Capsule can import data from various sources:

### Supported Import Sources

| Source | Format | Status |
|--------|--------|--------|
| Time Capsule Export | UTF/JSON | ✅ Fully Supported |
| Todoist | JSON | ✅ Fully Supported |
| Things 3 | JSON | ✅ Fully Supported |
| Generic JSON | JSON | ✅ Fully Supported |
| Generic CSV | CSV | ✅ Fully Supported |
| Apple Reminders | EventKit | 🚧 Planned |
| OmniFocus | OPML | 🚧 Planned |
| TickTick | JSON | 🚧 Planned |

### Migration Guides

#### From Todoist

1. Go to [todoist.com/settings/general](https://todoist.com/settings/general)
2. Scroll to "Export"
3. Click "Export as template"
4. Save the JSON file
5. In Time Capsule: Settings → Data Portability → Import → Choose Todoist
6. Select your exported JSON file

#### From Things 3

1. Select the tasks you want to export
2. Go to File → Export as JSON
3. Save the file
4. In Time Capsule: Settings → Data Portability → Import → Choose Things 3
5. Select your exported JSON file

## Backup System

Time Capsule includes an enterprise-grade backup system with encryption.

### Backup Features

- **AES-GCM Encryption**: Military-grade encryption with user password
- **LZFSE Compression**: Efficient storage using Apple's compression
- **Automatic Rotation**: Keeps 10 most recent backups
- **Integrity Verification**: Checksums to detect corruption
- **Metadata Tracking**: Size, date, task counts

### Creating a Backup

1. Open Settings → Data Portability → Backup
2. Click "Create Backup"
3. (Optional) Enter a backup name
4. (Optional) Enable encryption and set a password
5. Click "Create Backup"

**Important**: If you encrypt your backup, **remember your password**. There is no way to recover an encrypted backup without the password.

### Restoring a Backup

1. Open Settings → Data Portability → Backup
2. Select a backup from the list
3. Click "Restore"
4. (If encrypted) Enter your password
5. Choose restore options:
   - **Standard**: Add to existing data
   - **Full Restore**: Clear existing data first

## Privacy & Security

### What Data We Store

Time Capsule stores **only** what you explicitly create:

- **Tasks**: Title, description, tags, dates, priority
- **Analytics**: Completion times, skip counts (for AI suggestions)
- **Settings**: Your app preferences

### What We DON'T Store

- ❌ No cloud sync (unless you enable iCloud)
- ❌ No telemetry or usage tracking
- ❌ No advertising identifiers
- ❌ No location data (unless you use Focus Profiles)
- ❌ No contact information

### Data Location

All data is stored locally in:
```
~/Library/Application Support/TimeCapsule/
```

### Encryption

- **At Rest**: SwiftData encrypts data when device is locked (macOS FileVault)
- **Backups**: Optional AES-256-GCM encryption with user password
- **Export**: Optional encryption (planned feature)

## API & Integration

### Export API (Swift)

```swift
import TimeCapsule

let coordinator = ExportCoordinator(modelContext: modelContext)

// Export as UTF
let result = try await coordinator.export(
    format: .universalTaskFormat,
    options: .complete,
    destination: nil  // Will show save dialog
)

// Export as JSON
let jsonResult = try await coordinator.export(
    format: .json,
    options: ExportOptions(
        includeCompleted: true,
        includeArchived: false,
        includeSettings: false
    ),
    destination: URL(fileURLWithPath: "/path/to/export.json")
)
```

### Import API (Swift)

```swift
import TimeCapsule

let coordinator = ImportCoordinator(modelContext: modelContext)

let result = try await coordinator.importData(
    from: URL(fileURLWithPath: "/path/to/import.json"),
    source: .universalTaskFormat,
    options: ImportOptions(
        conflictStrategy: .keepBoth,
        preserveIds: false
    )
)

print("Imported: \(result.importedCount) tasks")
```

### Backup API (Swift)

```swift
import TimeCapsule

let exportCoordinator = ExportCoordinator(modelContext: modelContext)
let backupManager = BackupManager(
    modelContext: modelContext,
    exportCoordinator: exportCoordinator
)

// Create encrypted backup
let backup = try await backupManager.createBackup(
    name: "Pre-Migration Backup",
    encrypt: true,
    password: "SecurePassword123"
)

// Restore backup
let result = try await backupManager.restoreBackup(
    backup,
    password: "SecurePassword123",
    options: .fullRestore
)
```

## Data Deletion

### Selective Deletion

You can delete specific subsets of your data:

- **By Task**: Delete individual tasks
- **By Status**: Delete all completed/archived tasks
- **By Tag**: Delete all tasks with a specific tag
- **By Date Range**: Delete tasks created in a date range

### Complete Data Deletion

To delete **all** your data:

1. Open Settings → Data Portability → Privacy
2. Click "Delete All Data"
3. Type `DELETE ALL MY DATA` to confirm
4. Your data will be permanently deleted

**Warning**: This action cannot be undone. Create a backup first if you might want to restore later.

## Version Compatibility

### UTF Version History

| Version | Release Date | Changes |
|---------|--------------|---------|
| 1.0.0 | 2024-01-15 | Initial release |

### Forward Compatibility

Time Capsule can import **older** UTF versions. If you export from an older version and import to a newer version, data will be migrated automatically.

### Backward Compatibility

Time Capsule **cannot** import newer UTF versions. If the format version is newer than what your app supports, you'll receive an error message.

## Best Practices

### Regular Backups

We recommend:

- ✅ Weekly encrypted backups before major updates
- ✅ Monthly exports in UTF format to external storage
- ✅ Before migrating to a new device

### Password Management

For encrypted backups:

- ✅ Use a unique, strong password
- ✅ Store password in a password manager
- ✅ Don't use the same password as your Mac login
- ❌ Never share your backup password

### Data Hygiene

- Archive completed tasks older than 60 days
- Delete archived tasks yearly
- Export before deleting for historical records

## Troubleshooting

### Export Issues

**Problem**: Export fails with "No data to export"
- **Solution**: Make sure you have at least one task created

**Problem**: Can't save export file
- **Solution**: Check that you have write permissions to the destination folder

### Import Issues

**Problem**: Import fails with "Invalid format"
- **Solution**: Verify the file is a valid JSON/CSV file and not corrupted

**Problem**: Duplicate tasks after import
- **Solution**: Use the "Skip Duplicates" conflict resolution strategy

### Backup Issues

**Problem**: Cannot restore encrypted backup
- **Solution**: Verify you're using the correct password. If lost, the backup cannot be recovered.

**Problem**: Backup file is very large
- **Solution**: This is normal if you have many tasks. Backups are compressed but include all data.

## Future Roadmap

Planned data sovereignty features:

- 🚧 **Audit Logging**: Track all data access and modifications
- 🚧 **Data Anonymization**: Remove personal info while keeping analytics
- 🚧 **Privacy Dashboard**: Visual overview of all stored data
- 🚧 **Export Scheduling**: Automatic periodic exports
- 🚧 **Cloud Backup Options**: Encrypted backups to iCloud/Dropbox
- 🚧 **More Import Sources**: OmniFocus, Asana, Notion, Microsoft To Do

## Support

If you have questions about data sovereignty:

- 📧 Email: [email protected]
- 🐛 GitHub Issues: [github.com/kocheck/Time-Capsule/issues](https://github.com/kocheck/Time-Capsule/issues)
- 📖 Documentation: [timecapsule.app/docs](https://timecapsule.app/docs)

---

**Last Updated**: January 2024
**UTF Version**: 1.0.0
**Document Version**: 1.0
