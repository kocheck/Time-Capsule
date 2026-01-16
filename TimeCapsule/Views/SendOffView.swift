import SwiftUI
import SwiftData

struct SendOffView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TaskViewModel

    // Input mode toggle
    @State private var useNaturalLanguage: Bool = true

    // Natural language input
    @State private var naturalLanguageInput: String = ""
    @State private var parsedTask: ParsedTask?

    // Manual input
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var tags: [String] = []
    @State private var priority: TaskPriority = .normal

    @State private var showSuccess: Bool = false

    private let parser = NaturalLanguageParser()

    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: TaskViewModel(modelContext: modelContext))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Send Off a Task")
                    .font(.title2)
                    .fontWeight(.bold)

                // Input mode toggle
                Picker("Input Mode", selection: $useNaturalLanguage) {
                    Text("Natural Language").tag(true)
                    Text("Manual").tag(false)
                }
                .pickerStyle(.segmented)

                if useNaturalLanguage {
                    naturalLanguageInputSection
                } else {
                    manualInputSection
                }

                ActionButton(
                    title: "Send Off Task",
                    icon: "paperplane.fill",
                    style: .primary
                ) {
                    sendOffTask()
                }
                .disabled(useNaturalLanguage ? naturalLanguageInput.isBlank : title.isBlank)

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

    // MARK: - Natural Language Input Section

    private var naturalLanguageInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Describe your task")
                    .font(.headline)
                TextField(
                    "e.g., Remind me to call mom next week in the evening",
                    text: $naturalLanguageInput
                )
                .textFieldStyle(.roundedBorder)
                .onChange(of: naturalLanguageInput) { _, newValue in
                    if newValue.isNotBlank {
                        parsedTask = parser.parse(newValue)
                    } else {
                        parsedTask = nil
                    }
                }
            }

            // Preview of parsed result
            if let parsed = parsedTask, naturalLanguageInput.isNotBlank {
                parsedTaskPreview(parsed)
            }
        }
    }

    private func parsedTaskPreview(_ parsed: ParsedTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            Text("Preview")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                // Title
                HStack {
                    Text("Title:")
                        .foregroundColor(.secondary)
                    Text(parsed.title)
                        .fontWeight(.medium)
                }

                // Priority
                HStack {
                    Text("Priority:")
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: parsed.priority.iconName)
                        Text(parsed.priority.displayName)
                    }
                    .foregroundColor(priorityColor(parsed.priority))
                }

                // Tags
                if !parsed.tags.isEmpty {
                    HStack(alignment: .top) {
                        Text("Tags:")
                            .foregroundColor(.secondary)
                        FlowLayout(spacing: 4) {
                            ForEach(parsed.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }

                // Context hints
                if !parsed.contextHints.isEmpty {
                    HStack(alignment: .top) {
                        Text("Best time:")
                            .foregroundColor(.secondary)
                        Text(parsed.contextHints.joined(separator: ", "))
                    }
                }

                // Time hint
                if let timeHint = parsed.timeHint {
                    HStack {
                        Text("When:")
                            .foregroundColor(.secondary)
                        Text(timeHint.capitalized)
                    }
                }

                // Description
                if let desc = parsed.description {
                    HStack(alignment: .top) {
                        Text("Note:")
                            .foregroundColor(.secondary)
                        Text(desc)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .font(.subheadline)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .normal: return .primary
        case .low: return .gray
        }
    }

    // MARK: - Manual Input Section

    private var manualInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
        }
    }

    // MARK: - Actions

    private func sendOffTask() {
        do {
            if useNaturalLanguage, let parsed = parsedTask {
                try viewModel.createTask(from: parsed)

                // Reset form
                naturalLanguageInput = ""
                parsedTask = nil
            } else {
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
            }

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

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.origin.x, y: bounds.minY + frame.origin.y),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        let totalHeight = currentY + lineHeight
        let totalWidth = frames.map { $0.maxX }.max() ?? 0

        return (CGSize(width: totalWidth, height: totalHeight), frames)
    }
}
