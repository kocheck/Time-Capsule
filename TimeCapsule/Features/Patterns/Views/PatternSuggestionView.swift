import SwiftUI

/// Displays a pattern suggestion with accept/dismiss actions
struct PatternSuggestionView: View {
    let suggestion: PatternSuggestion
    var onAccept: () -> Void
    var onDismiss: () -> Void
    var onSnooze: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            details
            actions
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack {
            Image(systemName: "repeat")
                .foregroundStyle(.purple)

            Text("Recurring Pattern Detected")
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            ConfidenceBadge(confidence: suggestion.pattern.confidence)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(suggestion.message)
                .font(.headline)

            HStack(spacing: 16) {
                Label(suggestion.pattern.frequency.displayName, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("\(suggestion.pattern.occurrenceCount) times", systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let day = suggestion.pattern.preferredDayName {
                    Label(day, systemImage: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !suggestion.pattern.suggestedTags.isEmpty {
                HStack {
                    ForEach(suggestion.pattern.suggestedTags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var actions: some View {
        HStack {
            Button(role: .destructive) {
                onDismiss()
            } label: {
                Text("Not Now")
            }
            .buttonStyle(.bordered)

            if let onSnooze {
                Button {
                    onSnooze()
                } label: {
                    Text("Snooze")
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button {
                onAccept()
            } label: {
                Label("Create Task", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

/// Shows confidence level
private struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        Text(label)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch confidence {
        case 0.8...: return "High"
        case 0.6..<0.8: return "Medium"
        default: return "Low"
        }
    }

    private var color: Color {
        switch confidence {
        case 0.8...: return .green
        case 0.6..<0.8: return .yellow
        default: return .orange
        }
    }
}

/// Compact suggestion banner
struct PatternSuggestionBanner: View {
    let suggestion: PatternSuggestion
    var onAccept: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "repeat")
                .foregroundStyle(.purple)

            Text(suggestion.message)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.borderless)

            Button {
                onAccept()
            } label: {
                Image(systemName: "plus")
                    .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Full patterns management view
struct PatternsManagementView: View {
    let detector: PatternDetector

    @State private var isAnalyzing = false

    var body: some View {
        NavigationStack {
            List {
                Section("Suggestions") {
                    if detector.pendingSuggestions.isEmpty {
                        Text("No suggestions right now")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(detector.pendingSuggestions) { suggestion in
                            PatternSuggestionRow(
                                suggestion: suggestion,
                                onAccept: {
                                    _ = detector.acceptSuggestion(suggestion)
                                },
                                onDismiss: {
                                    detector.dismissSuggestion(suggestion)
                                }
                            )
                        }
                    }
                }

                Section("Detected Patterns") {
                    if detector.detectedPatterns.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)

                            Text("No patterns detected yet")
                                .foregroundStyle(.secondary)

                            Text("Complete more tasks to discover recurring patterns")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        ForEach(detector.detectedPatterns) { pattern in
                            PatternRow(pattern: pattern)
                        }
                    }
                }
            }
            .navigationTitle("Recurring Patterns")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        analyze()
                    } label: {
                        if isAnalyzing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isAnalyzing)
                }
            }
        }
    }

    private func analyze() {
        isAnalyzing = true
        Task {
            await detector.analyzePatterns()
            isAnalyzing = false
        }
    }
}

private struct PatternSuggestionRow: View {
    let suggestion: PatternSuggestion
    var onAccept: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(suggestion.suggestedTitle)
                .fontWeight(.medium)

            HStack {
                Label(suggestion.pattern.frequency.displayName, systemImage: "repeat")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Dismiss", role: .destructive, action: onDismiss)
                    .buttonStyle(.borderless)

                Button("Create", action: onAccept)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct PatternRow: View {
    let pattern: RecurringPattern

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(pattern.titlePattern)
                    .fontWeight(.medium)

                Spacer()

                if pattern.wasDismissed {
                    Text("Dismissed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Label(pattern.frequency.displayName, systemImage: "repeat")

                Label("\(pattern.occurrenceCount)x", systemImage: "number")

                Text(pattern.confidenceLabel)
                    .foregroundStyle(pattern.confidence >= 0.7 ? .green : .orange)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
