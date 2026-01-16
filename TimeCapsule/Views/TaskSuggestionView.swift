import SwiftUI
import SwiftData

struct TaskSuggestionView: View {
    @State private var viewModel: SuggestionViewModel

    init(modelContext: ModelContext, aiService: AIServiceProtocol) {
        _viewModel = State(initialValue: SuggestionViewModel(modelContext: modelContext, aiService: aiService))
    }

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxHeight: .infinity)
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    Task {
                        await viewModel.loadSuggestion()
                    }
                }
            } else if let task = viewModel.suggestedTask {
                taskSuggestionContent(task)
            } else {
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "All Done!",
                    message: "No pending tasks. Great work!",
                    action: nil,
                    actionTitle: nil
                )
            }
        }
        .padding()
        .task {
            await viewModel.loadSuggestion()
        }
    }

    @ViewBuilder
    private func taskSuggestionContent(_ task: TaskItem) -> some View {
        VStack(spacing: 16) {
            if viewModel.isFocusMode {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.orange)
                    Text("Focus Mode")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(16)
            }

            Text("Work on this task:")
                .font(.headline)
                .foregroundColor(.secondary)

            TaskCard(task: task)

            VStack(spacing: 12) {
                ActionButton(
                    title: "Complete",
                    icon: "checkmark.circle.fill",
                    style: .primary
                ) {
                    Task {
                        await viewModel.completeCurrentTask()
                    }
                }

                ActionButton(
                    title: "Skip",
                    icon: "forward.fill",
                    style: .secondary
                ) {
                    Task {
                        await viewModel.skipCurrentTask()
                    }
                }

                Button("Archive") {
                    Task {
                        await viewModel.archiveCurrentTask()
                    }
                }
                .foregroundColor(.secondary)
            }
        }
    }
}

struct ErrorView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
