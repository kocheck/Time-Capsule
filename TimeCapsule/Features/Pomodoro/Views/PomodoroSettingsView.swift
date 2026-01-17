import SwiftUI

/// Settings view for Pomodoro timer configuration
struct PomodoroSettingsView: View {
    @Bindable var settings: PomodoroSettings
    var onSave: (() -> Void)?

    var body: some View {
        Form {
            durationSection
            behaviorSection
            notificationSection
        }
        .formStyle(.grouped)
    }

    private var durationSection: some View {
        Section("Durations") {
            Stepper(
                "Work: \(settings.workMinutes) min",
                value: $settings.workMinutes,
                in: 1...60,
                step: 5
            )

            Stepper(
                "Short Break: \(settings.shortBreakMinutes) min",
                value: $settings.shortBreakMinutes,
                in: 1...30,
                step: 1
            )

            Stepper(
                "Long Break: \(settings.longBreakMinutes) min",
                value: $settings.longBreakMinutes,
                in: 5...60,
                step: 5
            )

            Stepper(
                "Sessions until long break: \(settings.sessionsUntilLongBreak)",
                value: $settings.sessionsUntilLongBreak,
                in: 2...8
            )
        }
    }

    private var behaviorSection: some View {
        Section("Behavior") {
            Toggle("Auto-start breaks", isOn: $settings.autoStartBreaks)
                .help("Automatically start break timer when work session ends")

            Toggle("Auto-start work sessions", isOn: $settings.autoStartWork)
                .help("Automatically start next work session when break ends")
        }
    }

    private var notificationSection: some View {
        Section("Notifications") {
            Toggle("Play sound", isOn: $settings.playSound)

            if settings.playSound {
                Picker("Sound", selection: $settings.soundName) {
                    Text("Glass").tag("Glass")
                    Text("Ping").tag("Ping")
                    Text("Pop").tag("Pop")
                    Text("Purr").tag("Purr")
                    Text("Sosumi").tag("Sosumi")
                    Text("Submarine").tag("Submarine")
                    Text("Tink").tag("Tink")
                }
            }

            Toggle("Show notification", isOn: $settings.showNotification)
        }
    }
}

// MARK: - Presets

extension PomodoroSettingsView {
    struct Preset: Identifiable {
        let id = UUID()
        let name: String
        let workMinutes: Int
        let shortBreakMinutes: Int
        let longBreakMinutes: Int
        let sessionsUntilLongBreak: Int
    }

    static let presets: [Preset] = [
        Preset(name: "Classic", workMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsUntilLongBreak: 4),
        Preset(name: "Extended Focus", workMinutes: 50, shortBreakMinutes: 10, longBreakMinutes: 30, sessionsUntilLongBreak: 2),
        Preset(name: "Short Bursts", workMinutes: 15, shortBreakMinutes: 3, longBreakMinutes: 10, sessionsUntilLongBreak: 4),
    ]
}

// MARK: - Quick Presets View

struct PomodoroPresetsView: View {
    @Bindable var settings: PomodoroSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Presets")
                .font(.headline)

            ForEach(PomodoroSettingsView.presets) { preset in
                Button {
                    applyPreset(preset)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(preset.name)
                                .fontWeight(.medium)
                            Text("\(preset.workMinutes)m work / \(preset.shortBreakMinutes)m break")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func applyPreset(_ preset: PomodoroSettingsView.Preset) {
        settings.workMinutes = preset.workMinutes
        settings.shortBreakMinutes = preset.shortBreakMinutes
        settings.longBreakMinutes = preset.longBreakMinutes
        settings.sessionsUntilLongBreak = preset.sessionsUntilLongBreak
    }
}
