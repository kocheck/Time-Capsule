import SwiftUI

/// Main Pomodoro timer display view
struct PomodoroTimerView: View {
    @Bindable var timer: PomodoroTimer
    var onLinkTask: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            phaseIndicator
            timerDisplay
            taskInfo
            controls
        }
        .padding()
    }

    private var phaseIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < timer.sessionsCompleted ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var timerDisplay: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 12)

            // Progress circle
            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(colorForPhase, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timer.progress)

            // Time display
            VStack(spacing: 4) {
                Text(timer.currentPhase.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(timer.formattedTime)
                    .font(.system(size: 48, weight: .light, design: .monospaced))

                if timer.isRunning || timer.isPaused {
                    Text(stateLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 200, height: 200)
    }

    @ViewBuilder
    private var taskInfo: some View {
        if let task = timer.currentTask {
            HStack {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
                Text(task.title)
                    .lineLimit(1)

                Button {
                    timer.currentTask = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Capsule())
        } else if timer.isIdle {
            Button {
                onLinkTask?()
            } label: {
                Label("Link a task", systemImage: "link.badge.plus")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            if timer.isIdle {
                Button {
                    timer.start(task: timer.currentTask)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else if timer.isPaused {
                Button {
                    timer.resume()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    timer.stop()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    timer.pause()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.title2)
                }
                .buttonStyle(.bordered)

                Button {
                    timer.skip()
                } label: {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    timer.stop()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var colorForPhase: Color {
        switch timer.currentPhase {
        case .work: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }

    private var stateLabel: String {
        switch timer.state {
        case .running: return "Running"
        case .paused: return "Paused"
        case .onBreak(let isLong): return isLong ? "Long Break" : "Short Break"
        case .idle: return ""
        }
    }
}

// MARK: - Compact Timer View (for menu bar)

struct PomodoroCompactView: View {
    @Bindable var timer: PomodoroTimer

    var body: some View {
        HStack(spacing: 8) {
            // Mini progress indicator
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(colorForPhase, lineWidth: 3)
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 24, height: 24)

            Text(timer.formattedTime)
                .font(.system(.body, design: .monospaced))
                .monospacedDigit()

            if timer.isIdle {
                Button {
                    timer.start()
                } label: {
                    Image(systemName: "play.fill")
                }
                .buttonStyle(.borderless)
            } else if timer.isPaused {
                Button {
                    timer.resume()
                } label: {
                    Image(systemName: "play.fill")
                }
                .buttonStyle(.borderless)
            } else {
                Button {
                    timer.pause()
                } label: {
                    Image(systemName: "pause.fill")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var colorForPhase: Color {
        switch timer.currentPhase {
        case .work: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
}
