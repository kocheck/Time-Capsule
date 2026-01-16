import SwiftUI
import SwiftData

struct DailyProgressView: View {
    @State private var viewModel: StatsViewModel

    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: StatsViewModel(modelContext: modelContext))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Streak Badge
                if viewModel.currentStreak > 0 {
                    StreakBadge(streak: viewModel.currentStreak)
                }

                // Today's Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today")
                        .font(.headline)

                    HStack(spacing: 20) {
                        StatBox(
                            icon: "checkmark.circle.fill",
                            value: "\(viewModel.todayCompletedCount)",
                            label: "Completed",
                            color: .green
                        )

                        StatBox(
                            icon: "forward.fill",
                            value: "\(viewModel.todaySkippedCount)",
                            label: "Skipped",
                            color: .orange
                        )

                        StatBox(
                            icon: "plus.circle.fill",
                            value: "\(viewModel.todayCreatedCount)",
                            label: "Created",
                            color: .blue
                        )
                    }

                    // Completion Rate
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Completion Rate")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)

                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: geometry.size.width * viewModel.todayCompletionRate, height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)

                        Text(String(format: "%.0f%%", viewModel.todayCompletionRate * 100))
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(Constants.cornerRadius)

                // Weekly Average
                VStack(alignment: .leading, spacing: 8) {
                    Text("7-Day Average")
                        .font(.headline)

                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.accentColor)
                        Text(viewModel.formattedCompletionRate)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(Constants.cornerRadius)

                // Total Completed
                VStack(alignment: .leading, spacing: 8) {
                    Text("All Time")
                        .font(.headline)

                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(viewModel.totalCompleted) tasks completed")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(Constants.cornerRadius)
            }
            .padding()
        }
        .onAppear {
            viewModel.loadStats()
        }
    }
}

struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
