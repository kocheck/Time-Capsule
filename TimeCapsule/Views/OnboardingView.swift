import SwiftUI
import SwiftData

struct OnboardingView: View {
    @State private var viewModel: SettingsViewModel
    @State private var currentPage = 0
    let onComplete: () -> Void

    init(modelContext: ModelContext, onComplete: @escaping () -> Void) {
        _viewModel = State(initialValue: SettingsViewModel(modelContext: modelContext))
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 24) {
            // Progress Indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index == currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            // Content
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                aiProviderPage.tag(1)
                permissionsPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 350)

            // Navigation
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                }

                Spacer()

                if currentPage < 2 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .frame(width: 400, height: 500)
    }

    private var welcomePage: some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            Text("Welcome to Time Capsule")
                .font(.title)
                .fontWeight(.bold)

            Text("Intelligent task management that learns from your behavior and suggests the right task at the right time.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }

    private var aiProviderPage: some View {
        VStack(spacing: 16) {
            Text("Choose AI Provider")
                .font(.title2)
                .fontWeight(.bold)

            Picker("AI Provider", selection: $viewModel.settings.aiProvider) {
                ForEach(AIProvider.allCases) { provider in
                    VStack(alignment: .leading) {
                        Text(provider.displayName)
                        Text(provider.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(provider)
                }
            }
            .pickerStyle(.radioGroup)
            .padding()
        }
    }

    private var permissionsPage: some View {
        VStack(spacing: 16) {
            Text("Permissions")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                PermissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Get daily reminders and progress updates",
                    isEnabled: $viewModel.settings.showDailyNotification
                )

                PermissionRow(
                    icon: "app.badge.fill",
                    title: "Badge Count",
                    description: "Show pending task count in dock",
                    isEnabled: $viewModel.settings.showBadgeCount
                )

                PermissionRow(
                    icon: "power",
                    title: "Launch at Login",
                    description: "Start Time Capsule when you log in",
                    isEnabled: $viewModel.settings.launchAtLogin
                )
            }
            .padding()
        }
    }

    private func completeOnboarding() {
        viewModel.completeOnboarding()
        onComplete()
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
    }
}
