import SwiftUI
import SwiftData

struct WeeklyDigestView: View {
    @State private var viewModel: DigestViewModel

    init(modelContext: ModelContext, aiService: AIServiceProtocol) {
        _viewModel = State(initialValue: DigestViewModel(modelContext: modelContext, aiService: aiService))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasDigest {
                    digestContent
                } else {
                    emptyStateView
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.loadDigest()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading digest...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Weekly Digest Yet")
                .font(.headline)

            Text("Generate a summary of your week's accomplishments, patterns, and suggestions for improvement.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            generateButton
        }
        .padding(.vertical, 40)
    }

    // MARK: - Digest Content

    private var digestContent: some View {
        VStack(spacing: 16) {
            // Header
            headerSection

            // Summary
            if !viewModel.summaryText.isEmpty {
                summarySection
            }

            // Weekly Stats
            statsSection

            // Accomplishments
            if !viewModel.accomplishments.isEmpty {
                accomplishmentsSection
            }

            // Patterns
            if !viewModel.patterns.isEmpty {
                patternsSection
            }

            // Suggestions
            if !viewModel.suggestions.isEmpty {
                suggestionsSection
            }

            // Stale Tasks
            if !viewModel.staleTasks.isEmpty {
                staleTasksSection
            }

            // Regenerate Button
            regenerateButton
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Digest")
                    .font(.headline)
                Text(viewModel.digestDateRange)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.accentColor)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(Constants.cornerRadius)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.summaryText)
                .font(.body)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(Constants.cornerRadius)
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            DigestStatBox(
                icon: "checkmark.circle.fill",
                value: "\(viewModel.weeklyStats.completed)",
                label: "Completed",
                color: .green
            )

            DigestStatBox(
                icon: "forward.fill",
                value: "\(viewModel.weeklyStats.skipped)",
                label: "Skipped",
                color: .orange
            )

            DigestStatBox(
                icon: "percent",
                value: viewModel.formattedCompletionRate,
                label: "Rate",
                color: .blue
            )
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(Constants.cornerRadius)
    }

    private var accomplishmentsSection: some View {
        DigestListSection(
            title: "Accomplishments",
            icon: "star.fill",
            iconColor: .yellow,
            items: viewModel.accomplishments
        )
    }

    private var patternsSection: some View {
        DigestListSection(
            title: "Patterns Noticed",
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .purple,
            items: viewModel.patterns
        )
    }

    private var suggestionsSection: some View {
        DigestListSection(
            title: "Suggestions",
            icon: "lightbulb.fill",
            iconColor: .orange,
            items: viewModel.suggestions
        )
    }

    private var staleTasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Needs Attention")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ForEach(viewModel.staleTasks.prefix(5), id: \.self) { task in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 6, height: 6)
                    Text(task)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            if viewModel.staleTasks.count > 5 {
                Text("+\(viewModel.staleTasks.count - 5) more stale tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(Constants.cornerRadius)
    }

    // MARK: - Buttons

    private var generateButton: some View {
        Button {
            Task {
                await viewModel.generateDigest()
            }
        } label: {
            HStack {
                if viewModel.isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(viewModel.isGenerating ? "Generating..." : "Generate Digest")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isGenerating)
    }

    private var regenerateButton: some View {
        Button {
            Task {
                await viewModel.regenerateDigest()
            }
        } label: {
            HStack {
                if viewModel.isGenerating {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text(viewModel.isGenerating ? "Regenerating..." : "Regenerate")
            }
            .font(.subheadline)
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.isGenerating)
    }
}

// MARK: - Supporting Views

struct DigestStatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DigestListSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(iconColor.opacity(0.5))
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(Constants.cornerRadius)
    }
}
