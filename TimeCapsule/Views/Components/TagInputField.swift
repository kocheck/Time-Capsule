import SwiftUI

struct TagInputField: View {
    @Binding var tags: [String]
    @State private var currentInput: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(text: tag) {
                        withAnimation {
                            tags.removeAll { $0 == tag }
                        }
                    }
                }

                TextField("Add tag...", text: $currentInput)
                    .textFieldStyle(.plain)
                    .frame(minWidth: 80)
                    .onSubmit {
                        addTag()
                    }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func addTag() {
        let trimmed = currentInput.trimmed.lowercased()
        if trimmed.isValidTag && !tags.contains(trimmed) {
            withAnimation {
                tags.append(trimmed)
            }
            currentInput = ""
        }
    }
}
