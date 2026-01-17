import SwiftUI
import Charts

/// Detailed view for a single tag's analytics
struct TagDetailView: View {
    let metrics: TagMetrics

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                statsGrid
                hourlyChart
                recommendations
            }
            .padding()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("#\(metrics.tag)")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                CompletionRateBadge(rate: metrics.completionRate)
            }

            Text("\(metrics.totalCreated) total tasks")
                .foregroundStyle(.secondary)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Completed",
                value: "\(metrics.totalCompleted)",
                subtitle: "of \(metrics.totalCreated)",
                color: .green
            )

            StatCard(
                title: "Avg Time",
                value: metrics.averageTimeFormatted ?? "N/A",
                subtitle: "to complete",
                color: .blue
            )

            StatCard(
                title: "Skip Rate",
                value: metrics.skipRateFormatted,
                subtitle: "of presentations",
                color: metrics.skipRate > 0.5 ? .red : .orange
            )
        }
    }

    private var hourlyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Completions by Hour")
                    .font(.headline)

                Spacer()

                if let bestHour = metrics.bestHourFormatted {
                    Text("Best: \(bestHour)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if metrics.completionsByHour.isEmpty {
                Text("No completion data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                let chartData = (0..<24).map { hour in
                    (hour: hour, count: metrics.completionsByHour[hour] ?? 0)
                }

                Chart(chartData, id: \.hour) { item in
                    BarMark(
                        x: .value("Hour", formatHour(item.hour)),
                        y: .value("Completions", item.count)
                    )
                    .foregroundStyle(item.hour == metrics.bestHour ? Color.green : Color.blue.opacity(0.7))
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 4)) { _ in
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var recommendations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                if metrics.completionRate < 0.5 {
                    RecommendationRow(
                        icon: "exclamationmark.triangle",
                        color: .orange,
                        text: "This tag has a low completion rate. Consider breaking tasks into smaller steps."
                    )
                }

                if metrics.skipRate > 0.5 {
                    RecommendationRow(
                        icon: "arrow.uturn.right",
                        color: .red,
                        text: "Tasks with this tag are frequently skipped. Review if they're still relevant."
                    )
                }

                if let bestHour = metrics.bestHour {
                    RecommendationRow(
                        icon: "clock",
                        color: .green,
                        text: "You're most productive with #\(metrics.tag) tasks around \(formatHourDescription(bestHour))."
                    )
                }

                if metrics.completionRate >= 0.7 && metrics.skipRate < 0.3 {
                    RecommendationRow(
                        icon: "star.fill",
                        color: .yellow,
                        text: "Great job! You handle #\(metrics.tag) tasks well."
                    )
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }

    private func formatHourDescription(_ hour: Int) -> String {
        switch hour {
        case 5..<9: return "early morning"
        case 9..<12: return "mid-morning"
        case 12..<14: return "around lunch"
        case 14..<17: return "afternoon"
        case 17..<20: return "early evening"
        case 20..<23: return "evening"
        default: return "night"
        }
    }
}

// MARK: - Supporting Views

private struct CompletionRateBadge: View {
    let rate: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
            Text("\(Int(rate * 100))%")
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }

    private var color: Color {
        switch rate {
        case 0.7...: return .green
        case 0.4..<0.7: return .yellow
        default: return .red
        }
    }

    private var iconName: String {
        switch rate {
        case 0.7...: return "checkmark.circle.fill"
        case 0.4..<0.7: return "minus.circle.fill"
        default: return "xmark.circle.fill"
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RecommendationRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
        }
    }
}
