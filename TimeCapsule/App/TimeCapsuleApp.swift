import SwiftUI
import SwiftData
import os.log

@main
struct TimeCapsuleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showStorageWarning = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
            DailyStats.self,
            AppSettings.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Log the error for diagnostics
            Logger().error("Failed to create ModelContainer: \(error.localizedDescription)")
            
            // Attempt recovery with in-memory storage as fallback
            do {
                let fallbackConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                Logger().warning("Using in-memory storage as fallback - data will not persist")
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                // If even in-memory fails, this is a critical system issue
                Logger().critical("Failed to create fallback ModelContainer: \(error.localizedDescription)")
                // As a last resort, try with the most basic configuration
                // swiftlint:disable:next force_try
                return try! ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
                )
            }
        }
    }()

    var body: some Scene {
        MenuBarExtra("Time Capsule", systemImage: "hourglass") {
            ContentView(showStorageWarning: $showStorageWarning)
                .modelContainer(sharedModelContainer)
                .environment(\.appDelegate, appDelegate)
                .onAppear {
                    // Check if we're using in-memory storage (fallback mode)
                    if let config = sharedModelContainer.configurations.first,
                       config.isStoredInMemoryOnly {
                        showStorageWarning = true
                    }
                }
        }
        .menuBarExtraStyle(.window)
    }
}

// Environment key for AppDelegate
private struct AppDelegateKey: EnvironmentKey {
    static let defaultValue: AppDelegate? = nil
}

extension EnvironmentValues {
    var appDelegate: AppDelegate? {
        get { self[AppDelegateKey.self] }
        set { self[AppDelegateKey.self] = newValue }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var settingsViewModel: SettingsViewModel?
    @State private var showOnboarding = false
    @Binding var showStorageWarning: Bool

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(modelContext: modelContext) {
                    showOnboarding = false
                }
            } else {
                MenuBarView(modelContext: modelContext)
            }
        }
        .alert("Storage Warning", isPresented: $showStorageWarning) {
            Button("OK") {
                showStorageWarning = false
            }
        } message: {
            Text("Time Capsule could not access persistent storage. Your data will not be saved between sessions. Please check your disk permissions and available space, then restart the app.")
        }
        .onAppear {
            setupApp()
        }
    }

    private func setupApp() {
        let viewModel = SettingsViewModel(modelContext: modelContext)
        settingsViewModel = viewModel

        if !viewModel.hasCompletedOnboarding {
            showOnboarding = true
        }

        // Request notification permissions
        Task {
            _ = try? await NotificationService.shared.requestAuthorization()
        }

        // Schedule daily notification if enabled
        if viewModel.settings.showDailyNotification {
            NotificationService.shared.scheduleDailyNotification(
                hour: viewModel.settings.dailyNotificationHour,
                minute: viewModel.settings.dailyNotificationMinute
            )
        }
    }
}
