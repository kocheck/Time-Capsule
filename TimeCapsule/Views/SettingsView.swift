import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var showingDataPortability = false

    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: SettingsViewModel(modelContext: modelContext))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // AI Provider
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Provider")
                        .font(.headline)

                    Picker("AI Provider", selection: $viewModel.settings.aiProvider) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    Text(viewModel.settings.aiProvider.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Ollama Settings
                if viewModel.settings.aiProvider == .ollama {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ollama Endpoint")
                            .font(.subheadline)
                        TextField("Endpoint", text: $viewModel.settings.ollamaEndpoint)
                            .textFieldStyle(.roundedBorder)

                        Text("Model")
                            .font(.subheadline)
                        TextField("Model", text: $viewModel.settings.ollamaModel)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Divider()

                // Notifications
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notifications")
                        .font(.headline)

                    Toggle("Daily Reminder", isOn: $viewModel.settings.showDailyNotification)

                    if viewModel.settings.showDailyNotification {
                        HStack {
                            Text("Time:")
                            Stepper(
                                "\(viewModel.settings.dailyNotificationHour):\(String(format: "%02d", viewModel.settings.dailyNotificationMinute))",
                                value: $viewModel.settings.dailyNotificationHour,
                                in: 0...23
                            )
                        }
                    }

                    Toggle("Show Badge Count", isOn: $viewModel.settings.showBadgeCount)
                }

                Divider()

                // Task Management
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task Management")
                        .font(.headline)

                    HStack {
                        Text("Skip Threshold:")
                        Stepper("\(viewModel.settings.skipThreshold)", value: $viewModel.settings.skipThreshold, in: 1...10)
                    }

                    HStack {
                        Text("Stale Task Days:")
                        Stepper("\(viewModel.settings.staleTaskDays)", value: $viewModel.settings.staleTaskDays, in: 7...90)
                    }
                }

                Divider()

                // General
                VStack(alignment: .leading, spacing: 8) {
                    Text("General")
                        .font(.headline)

                    Toggle("Launch at Login", isOn: $viewModel.settings.launchAtLogin)

                    Picker("Theme", selection: $viewModel.settings.theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                // Data Portability
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Portability")
                        .font(.headline)

                    Text("Export, import, or backup your data. Your data, your control.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button {
                        showingDataPortability = true
                    } label: {
                        Label("Manage Data", systemImage: "square.and.arrow.up.on.square")
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                // Save Button
                HStack {
                    ActionButton(
                        title: "Save Settings",
                        icon: "checkmark.circle.fill",
                        style: .primary
                    ) {
                        viewModel.saveSettings()
                    }

                    if viewModel.saveSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                // Reset Button
                Button("Reset to Defaults") {
                    viewModel.resetToDefaults()
                }
                .foregroundColor(.red)

                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingDataPortability) {
            DataPortabilityView()
        }
    }
}
