import SwiftUI

/// A banner that displays a productivity insight
struct InsightBannerView: View {
    let insight: ProductivityInsight
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.message)
                    .font(.subheadline)

                HStack(spacing: 8) {
                    Text(insight.confidenceLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("Based on \(insight.basedOnSamples) tasks")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// A compact insight indicator for use in task rows
struct InsightIndicatorView: View {
    let suggestedHour: Int?
    let score: Double

    var body: some View {
        if let hour = suggestedHour, score > 0.7 {
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.caption2)
                Text("Best at \(formatHour(hour))")
                    .font(.caption2)
            }
            .foregroundStyle(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date).lowercased()
    }
}

/// A "good time to work" indicator
struct OptimalTimeIndicatorView: View {
    let isOptimalTime: Bool
    let message: String?

    var body: some View {
        if isOptimalTime {
            HStack(spacing: 6) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)

                if let message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        InsightBannerView(
            insight: ProductivityInsight(
                message: "You complete #coding tasks 73% faster in the morning",
                confidence: 0.85,
                basedOnSamples: 24,
                tags: ["coding"],
                suggestedHour: 9
            )
        )

        InsightIndicatorView(suggestedHour: 10, score: 0.8)

        OptimalTimeIndicatorView(isOptimalTime: true, message: "Good time for #coding")
    }
    .padding()
}
