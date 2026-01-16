import SwiftUI
import SwiftData

struct SendOffView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TaskViewModel

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var tags: [String] = []
    @State private var priority: TaskPriority = .normal
    @State private var showSuccess: Bool = false

    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: TaskViewModel(modelContext: modelContext))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Send Off a Task")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                    TextField("What needs to be done?", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.headline)
                    TextEditor(text: $description)
                        .frame(height: 80)
                        .padding(4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority")
                        .font(.headline)
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases) { priority in
                            HStack {
                                Image(systemName: priority.iconName)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    TagInputField(tags: $tags)
                }

                ActionButton(
                    title: "Send Off Task",
                    icon: "paperplane.fill",
                    style: .primary
                ) {
                    sendOffTask()
                }
                .disabled(title.isBlank)

                if showSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Task sent off successfully!")
                            .foregroundColor(.secondary)
                    }
                    .transition(.opacity)
                }

                Spacer()
            }
            .padding()
        }
    }

    private func sendOffTask() {
        do {
            try viewModel.createTask(
                title: title,
                description: description.isBlank ? nil : description,
                tags: tags,
                priority: priority
            )

            // Reset form
            title = ""
            description = ""
            tags = []
            priority = .normal

            // Show success
            withAnimation {
                showSuccess = true
            }

            // Hide success message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSuccess = false
                }
            }
        } catch {
            viewModel.error = error
        }
    }
}
