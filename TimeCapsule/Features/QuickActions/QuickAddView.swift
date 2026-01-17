import SwiftUI

/// Quick add task floating panel
struct QuickAddView: View {
    @Binding var title: String
    @Binding var tags: [String]
    @Binding var priority: TaskPriority

    @State private var newTag = ""

    var onSubmit: () -> Void
    var onCancel: () -> Void

    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            header
            titleField
            tagsSection
            prioritySection
            actionButtons
        }
        .padding(20)
        .frame(width: 400)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 20)
        .onAppear {
            isTitleFocused = true
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.blue)
            Text("Quick Add Task")
                .font(.headline)
            Spacer()

            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
    }

    private var titleField: some View {
        TextField("What needs to be done?", text: $title)
            .textFieldStyle(.plain)
            .font(.title3)
            .padding(12)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .focused($isTitleFocused)
            .onSubmit {
                if !title.isEmpty {
                    onSubmit()
                }
            }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(.plain)
                    .onSubmit { addTag() }

                Button("Add") { addTag() }
                    .disabled(newTag.isEmpty)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding(8)
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                                .font(.caption)

                            Button {
                                tags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var prioritySection: some View {
        HStack {
            Text("Priority:")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Priority", selection: $priority) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    Text(priority.displayName).tag(priority)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var actionButtons: some View {
        HStack {
            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.escape, modifiers: [])

            Spacer()

            Button("Add Task") {
                onSubmit()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(title.isEmpty)
        }
    }

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty, !tags.contains(tag) else { return }
        tags.append(tag)
        newTag = ""
    }
}

/// Minimal quick add popover for menu bar
struct QuickAddPopover: View {
    @State private var title = ""
    var onSubmit: (String) -> Void
    var onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            TextField("Quick task...", text: $title)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    if !title.isEmpty {
                        onSubmit(title)
                    }
                }

            Button {
                if !title.isEmpty {
                    onSubmit(title)
                }
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.borderless)
            .disabled(title.isEmpty)
        }
        .padding(12)
        .frame(width: 280)
        .onAppear {
            isFocused = true
        }
    }
}

/// Shortcut settings view
struct ShortcutSettingsView: View {
    let shortcutsService: GlobalShortcutsService

    var body: some View {
        Form {
            Section("Global Shortcuts") {
                Toggle("Enable global shortcuts", isOn: Binding(
                    get: { shortcutsService.isEnabled },
                    set: { shortcutsService.isEnabled = $0 }
                ))

                HStack {
                    Text("Quick Add Task")
                    Spacer()
                    Text(shortcutsService.quickAddShortcut.displayString)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                HStack {
                    Text("Show App")
                    Spacer()
                    Text(shortcutsService.showAppShortcut.displayString)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Section {
                Text("Note: Global shortcuts require Accessibility permissions in System Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
