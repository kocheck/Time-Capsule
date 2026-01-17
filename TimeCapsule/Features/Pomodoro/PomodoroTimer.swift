import Foundation
import SwiftData
import Combine

/// Manages the Pomodoro timer state and logic
@Observable
class PomodoroTimer {
    enum State: Equatable {
        case idle
        case running
        case paused
        case onBreak(isLong: Bool)
    }

    enum Phase: Equatable {
        case work
        case shortBreak
        case longBreak

        var displayName: String {
            switch self {
            case .work: return "Focus Time"
            case .shortBreak: return "Short Break"
            case .longBreak: return "Long Break"
            }
        }
    }

    // MARK: - Published State

    var state: State = .idle
    var currentPhase: Phase = .work
    var remainingSeconds: Int = 0
    var currentTask: TaskItem?
    var sessionsCompleted: Int = 0
    var currentSession: PomodoroSession?

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private var settings: PomodoroSettings
    private var timer: Timer?
    private var sessionStartTime: Date?

    // MARK: - Computed Properties

    var isRunning: Bool {
        state == .running || state == .onBreak(isLong: false) || state == .onBreak(isLong: true)
    }

    var isPaused: Bool {
        state == .paused
    }

    var isIdle: Bool {
        state == .idle
    }

    var progress: Double {
        let total = totalSecondsForCurrentPhase
        guard total > 0 else { return 0 }
        return Double(total - remainingSeconds) / Double(total)
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var totalSecondsForCurrentPhase: Int {
        switch currentPhase {
        case .work: return settings.workSeconds
        case .shortBreak: return settings.shortBreakSeconds
        case .longBreak: return settings.longBreakSeconds
        }
    }

    // MARK: - Initialization

    init(modelContext: ModelContext, settings: PomodoroSettings? = nil) {
        self.modelContext = modelContext
        self.settings = settings ?? PomodoroSettings()
        self.remainingSeconds = self.settings.workSeconds
    }

    // MARK: - Timer Controls

    /// Starts a new work session
    func start(task: TaskItem? = nil) {
        currentTask = task
        currentPhase = .work
        remainingSeconds = settings.workSeconds
        state = .running
        sessionStartTime = Date()

        // Create session record
        let session = PomodoroSession(
            taskId: task?.id,
            taskTitle: task?.title,
            tags: task?.tags ?? [],
            plannedMinutes: settings.workMinutes
        )
        currentSession = session
        modelContext.insert(session)
        try? modelContext.save()

        startTimer()
    }

    /// Pauses the timer
    func pause() {
        guard state == .running else { return }
        state = .paused
        stopTimer()
    }

    /// Resumes a paused timer
    func resume() {
        guard state == .paused else { return }
        state = .running
        startTimer()
    }

    /// Stops the timer completely
    func stop() {
        // Mark session as interrupted if we were in a work phase
        if currentPhase == .work, let session = currentSession {
            session.markInterrupted()
            try? modelContext.save()
        }

        reset()
    }

    /// Skips to the next phase
    func skip() {
        stopTimer()

        switch currentPhase {
        case .work:
            // Complete the current session
            if let session = currentSession {
                session.markCompleted()
                try? modelContext.save()
            }
            sessionsCompleted += 1
            moveToBreak()

        case .shortBreak, .longBreak:
            // Move back to work
            startNextWorkSession()
        }
    }

    /// Updates settings
    func updateSettings(_ newSettings: PomodoroSettings) {
        settings = newSettings
        if state == .idle {
            remainingSeconds = settings.workSeconds
        }
    }

    // MARK: - Private Methods

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            handlePhaseComplete()
            return
        }

        remainingSeconds -= 1

        if remainingSeconds == 0 {
            handlePhaseComplete()
        }
    }

    private func handlePhaseComplete() {
        stopTimer()

        switch currentPhase {
        case .work:
            // Complete the session
            if let session = currentSession {
                session.markCompleted()
                try? modelContext.save()
            }
            sessionsCompleted += 1

            // Play sound / show notification
            notifyCompletion()

            if settings.autoStartBreaks {
                moveToBreak()
                startTimer()
            } else {
                moveToBreak()
                state = .paused
            }

        case .shortBreak, .longBreak:
            notifyCompletion()

            if settings.autoStartWork {
                startNextWorkSession()
                startTimer()
            } else {
                state = .idle
                currentPhase = .work
                remainingSeconds = settings.workSeconds
            }
        }
    }

    private func moveToBreak() {
        if sessionsCompleted >= settings.sessionsUntilLongBreak {
            currentPhase = .longBreak
            remainingSeconds = settings.longBreakSeconds
            sessionsCompleted = 0
            state = .onBreak(isLong: true)
        } else {
            currentPhase = .shortBreak
            remainingSeconds = settings.shortBreakSeconds
            state = .onBreak(isLong: false)
        }
    }

    private func startNextWorkSession() {
        currentPhase = .work
        remainingSeconds = settings.workSeconds
        state = .running
        sessionStartTime = Date()

        // Create new session
        let session = PomodoroSession(
            taskId: currentTask?.id,
            taskTitle: currentTask?.title,
            tags: currentTask?.tags ?? [],
            plannedMinutes: settings.workMinutes
        )
        currentSession = session
        modelContext.insert(session)
        try? modelContext.save()

        startTimer()
    }

    private func reset() {
        stopTimer()
        state = .idle
        currentPhase = .work
        remainingSeconds = settings.workSeconds
        currentTask = nil
        currentSession = nil
        sessionStartTime = nil
    }

    private func notifyCompletion() {
        if settings.playSound {
            NSSound(named: NSSound.Name(settings.soundName))?.play()
        }

        // Notification would be handled by NotificationService
    }
}
