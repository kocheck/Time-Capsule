import SwiftUI
import EventKit

/// Shows current availability status
struct AvailabilityIndicatorView: View {
    let calendarService: CalendarService

    var body: some View {
        HStack(spacing: 8) {
            statusIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(calendarService.availabilitySuggestion)
                    .font(.caption)

                if let next = calendarService.nextEvent {
                    Text("Next: \(next.title ?? "Event") at \(formatTime(next.startDate))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var statusIcon: some View {
        Image(systemName: iconName)
            .foregroundStyle(iconColor)
    }

    private var iconName: String {
        if calendarService.isGoodTimeForDeepWork {
            return "brain.head.profile"
        } else if calendarService.currentFreeGap != nil {
            return "checkmark.circle"
        } else if let minutes = calendarService.minutesUntilNextEvent, minutes < 30 {
            return "clock.badge.exclamationmark"
        } else {
            return "calendar"
        }
    }

    private var iconColor: Color {
        if calendarService.isGoodTimeForDeepWork {
            return .green
        } else if calendarService.currentFreeGap != nil {
            return .blue
        } else {
            return .orange
        }
    }

    private var backgroundColor: Color {
        iconColor
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Compact availability badge for menu bar
struct AvailabilityBadgeView: View {
    let calendarService: CalendarService

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            if let gap = calendarService.currentFreeGap {
                Text("\(gap.durationMinutes)m free")
                    .font(.caption2)
            } else if let minutes = calendarService.minutesUntilNextEvent, minutes < 30 {
                Text("\(minutes)m to mtg")
                    .font(.caption2)
            }
        }
    }

    private var statusColor: Color {
        if calendarService.isGoodTimeForDeepWork {
            return .green
        } else if calendarService.currentFreeGap != nil {
            return .blue
        } else {
            return .orange
        }
    }
}

/// Full calendar overview showing free time gaps
struct CalendarOverviewView: View {
    let calendarService: CalendarService

    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            authorizationSection
            availabilitySection
            eventsSection
        }
        .padding()
        .task {
            if calendarService.isAuthorized {
                await calendarService.fetchTodayEvents()
            }
            isLoading = false
        }
    }

    private var header: some View {
        HStack {
            Text("Today's Availability")
                .font(.headline)

            Spacer()

            Button {
                Task {
                    await calendarService.fetchTodayEvents()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
        }
    }

    @ViewBuilder
    private var authorizationSection: some View {
        if !calendarService.isAuthorized {
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("Calendar access needed")
                    .font(.subheadline)

                Text("Allow access to see your availability and get better task suggestions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Enable Calendar Access") {
                    Task {
                        await calendarService.requestAccess()
                        if calendarService.isAuthorized {
                            await calendarService.fetchTodayEvents()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    @ViewBuilder
    private var availabilitySection: some View {
        if calendarService.isAuthorized {
            VStack(alignment: .leading, spacing: 8) {
                Text("Free Time")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if calendarService.freeTimeGaps.isEmpty {
                    Text("No free time slots found today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(calendarService.freeTimeGaps) { gap in
                        FreeTimeGapRow(gap: gap)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var eventsSection: some View {
        if calendarService.isAuthorized && !calendarService.todayEvents.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Upcoming Events")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(calendarService.todayEvents.prefix(5), id: \.eventIdentifier) { event in
                    EventRow(event: event)
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct FreeTimeGapRow: View {
    let gap: FreeTimeGap

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(gap.isGoodForDeepWork ? Color.green : Color.blue)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(gap.durationFormatted)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(timeFormatter.string(from: gap.start)) - \(timeFormatter.string(from: gap.end))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if gap.isGoodForDeepWork {
                Label("Deep Work", systemImage: "brain.head.profile")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } else if gap.isGoodForQuickTask {
                Label("Quick Task", systemImage: "bolt")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct EventRow: View {
    let event: EKEvent

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack {
            Circle()
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title ?? "Untitled Event")
                    .font(.subheadline)
                    .lineLimit(1)

                Text(timeFormatter.string(from: event.startDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}
