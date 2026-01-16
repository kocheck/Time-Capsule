import SwiftUI
import SwiftData

@main
struct TimeCapsuleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra("Time Capsule", systemImage: "hourglass") {
            ContentView()
                .modelContainer(sharedModelContainer)
                .environment(\.appDelegate, appDelegate)
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
