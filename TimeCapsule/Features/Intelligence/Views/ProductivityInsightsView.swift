import SwiftUI
import Charts

/// Full productivity insights dashboard
struct ProductivityInsightsView: View {
    let engine: PredictiveEngine

    @State private var insights: [ProductivityInsight] = []
    @State private var hourlyStats: [TimeSlotStats] = []
    @State private var dayStats: [DayOfWeekStats] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    insightsSection
                    hourlyChartSection
                    weeklyChartSection
                }
            }
            .padding()
        }
        .task {
            await loadData()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Productivity Insights")
                .font(.title)
                .fontWeight(.bold)

            Text("Learn when you work best based on your completion patterns")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var insightsSection: some View {
        if insights.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("Not enough data yet")
                    .font(.headline)

                Text("Complete at least 5 tasks to start seeing insights")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Patterns")
                    .font(.headline)

                ForEach(insights.prefix(5)) { insight in
                    InsightBannerView(insight: insight)
                }
            }
        }
    }

    private var hourlyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completions by Hour")
                .font(.headline)

            if hourlyStats.isEmpty || hourlyStats.allSatisfy({ $0.completionCount == 0 }) {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(hourlyStats, id: \.hourOfDay) { stat in
                    BarMark(
                        x: .value("Hour", stat.hourLabel),
                        y: .value("Completions", stat.completionCount)
                    )
                    .foregroundStyle(stat.isProductiveHour ? Color.green : Color.blue.opacity(0.7))
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 3)) { value in
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completions by Day")
                .font(.headline)

            if dayStats.isEmpty || dayStats.allSatisfy({ $0.completionCount == 0 }) {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(dayStats, id: \.dayOfWeek) { stat in
                    BarMark(
                        x: .value("Day", stat.shortDayName),
                        y: .value("Completions", stat.completionCount)
                    )
                    .foregroundStyle(Color.purple.opacity(0.7))
                }
                .frame(height: 150)
            }

            // Best day summary
            if let bestDay = dayStats.max(by: { $0.completionCount < $1.completionCount }),
               bestDay.completionCount > 0 {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Your most productive day is \(bestDay.dayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadData() async {
        isLoading = true

        async let loadedInsights = engine.getInsights()
        async let loadedHourly = engine.getHourlyStats()
        async let loadedDaily = engine.getDayOfWeekStats()

        insights = await loadedInsights
        hourlyStats = await loadedHourly
        dayStats = await loadedDaily

        isLoading = false
    }
}

// MARK: - Mini Insights Widget

/// A compact insights summary for the main view
struct InsightsSummaryView: View {
    let engine: PredictiveEngine

    @State private var topInsight: ProductivityInsight?
    @State private var currentScore: Double = 0.5

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.purple)
                Text("Insights")
                    .font(.headline)
            }

            if let insight = topInsight {
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Complete more tasks to unlock insights")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Current time quality indicator
            HStack {
                Text("Current productivity:")
                    .font(.caption2)

                ProgressView(value: currentScore)
                    .tint(scoreColor)

                Text("\(Int(currentScore * 100))%")
                    .font(.caption2)
                    .monospacedDigit()
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            await loadData()
        }
    }

    private var scoreColor: Color {
        switch currentScore {
        case 0.7...: return .green
        case 0.4..<0.7: return .yellow
        default: return .red
        }
    }

    private func loadData() async {
        let insights = await engine.getInsights()
        topInsight = insights.first
    }
}
