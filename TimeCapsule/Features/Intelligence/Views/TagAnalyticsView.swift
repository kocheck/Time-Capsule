import SwiftUI
import Charts

/// View displaying analytics for all tags
struct TagAnalyticsView: View {
    let service: TagAnalyticsService

    @State private var tagMetrics: [TagMetrics] = []
    @State private var selectedTag: TagMetrics?
    @State private var isLoading = true

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let selected = selectedTag {
                TagDetailView(metrics: selected)
            } else {
                ContentUnavailableView(
                    "Select a Tag",
                    systemImage: "tag",
                    description: Text("Choose a tag to see detailed analytics")
                )
            }
        }
        .task {
            await loadData()
        }
    }

    private var sidebar: some View {
        List(selection: $selectedTag) {
            if isLoading {
                ProgressView()
            } else if tagMetrics.isEmpty {
                ContentUnavailableView(
                    "No Tags",
                    systemImage: "tag.slash",
                    description: Text("Create tasks with tags to see analytics")
                )
            } else {
                Section("All Tags") {
                    ForEach(tagMetrics) { metrics in
                        TagRow(metrics: metrics)
                            .tag(metrics)
                    }
                }
            }
        }
        .navigationTitle("Tag Analytics")
        .listStyle(.sidebar)
    }

    private func loadData() async {
        isLoading = true
        tagMetrics = await service.getAllTagMetrics()
        isLoading = false

        // Auto-select first tag if none selected
        if selectedTag == nil {
            selectedTag = tagMetrics.first
        }
    }
}

// MARK: - Tag Row

private struct TagRow: View {
    let metrics: TagMetrics

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("#\(metrics.tag)")
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text("\(metrics.totalCreated) tasks")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(metrics.completionRateFormatted)
                        .font(.caption)
                        .foregroundStyle(rateColor)
                }
            }

            Spacer()

            // Completion rate indicator
            CircularProgressView(progress: metrics.completionRate, size: 32)
        }
        .padding(.vertical, 4)
    }

    private var rateColor: Color {
        switch metrics.completionRate {
        case 0.7...: return .green
        case 0.4..<0.7: return .yellow
        default: return .red
        }
    }
}

// MARK: - Circular Progress

private struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }

    private var progressColor: Color {
        switch progress {
        case 0.7...: return .green
        case 0.4..<0.7: return .yellow
        default: return .red
        }
    }
}
