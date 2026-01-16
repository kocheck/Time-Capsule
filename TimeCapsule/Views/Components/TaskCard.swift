import SwiftUI

struct TaskCard: View {
    let task: TaskItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: task.priority.iconName)
                    .foregroundColor(priorityColor)

                Text(task.title)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()
            }

            if let description = task.taskDescription, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            if !task.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(task.tags, id: \.self) { tag in
                        TagChip(text: tag)
                    }
                }
            }

            HStack {
                Label("\(task.daysSinceCreation)d", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if task.skipCount > 0 {
                    Label("\(task.skipCount)", systemImage: "forward.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(Constants.cornerRadius)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .normal: return .blue
        case .low: return .gray
        }
    }
}
