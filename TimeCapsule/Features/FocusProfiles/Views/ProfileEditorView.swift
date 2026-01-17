import SwiftUI

/// Editor view for creating or modifying a focus profile
struct ProfileEditorView: View {
    let manager: FocusProfileManager
    let profile: FocusProfile?

    @State private var name: String = ""
    @State private var selectedIcon: String = "person.fill"
    @State private var selectedColor: String = "blue"
    @State private var includeTags: [String] = []
    @State private var excludeTags: [String] = []
    @State private var scheduleEnabled = false
    @State private var scheduleStartHour = 9
    @State private var scheduleEndHour = 17
    @State private var scheduleDays: Set<Int> = [2, 3, 4, 5, 6]

    @State private var newIncludeTag = ""
    @State private var newExcludeTag = ""

    @Environment(\.dismiss) private var dismiss

    private var isNewProfile: Bool { profile == nil }

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                tagFilterSection
                scheduleSection
            }
            .formStyle(.grouped)
            .navigationTitle(isNewProfile ? "New Profile" : "Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear {
                loadProfile()
            }
        }
        .frame(minWidth: 400, minHeight: 400)
    }

    private var basicInfoSection: some View {
        Section("Basic Info") {
            TextField("Name", text: $name)

            Picker("Icon", selection: $selectedIcon) {
                ForEach(FocusProfile.availableIcons, id: \.self) { icon in
                    Label(icon, systemImage: icon).tag(icon)
                }
            }

            Picker("Color", selection: $selectedColor) {
                ForEach(FocusProfile.availableColors, id: \.self) { color in
                    HStack {
                        Circle()
                            .fill(colorFromString(color))
                            .frame(width: 16, height: 16)
                        Text(color.capitalized)
                    }
                    .tag(color)
                }
            }
        }
    }

    private var tagFilterSection: some View {
        Section("Tag Filters") {
            // Include tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Include tags (show only tasks with these)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("Add tag", text: $newIncludeTag)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addIncludeTag() }

                    Button("Add") { addIncludeTag() }
                        .disabled(newIncludeTag.isEmpty)
                }

                FlowLayout(spacing: 4) {
                    ForEach(includeTags, id: \.self) { tag in
                        TagChip(tag: tag, color: .green) {
                            includeTags.removeAll { $0 == tag }
                        }
                    }
                }
            }

            Divider()

            // Exclude tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Exclude tags (hide tasks with these)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("Add tag", text: $newExcludeTag)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addExcludeTag() }

                    Button("Add") { addExcludeTag() }
                        .disabled(newExcludeTag.isEmpty)
                }

                FlowLayout(spacing: 4) {
                    ForEach(excludeTags, id: \.self) { tag in
                        TagChip(tag: tag, color: .red) {
                            excludeTags.removeAll { $0 == tag }
                        }
                    }
                }
            }
        }
    }

    private var scheduleSection: some View {
        Section("Schedule") {
            Toggle("Enable automatic activation", isOn: $scheduleEnabled)

            if scheduleEnabled {
                HStack {
                    Text("Active from")
                    Picker("Start", selection: $scheduleStartHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()

                    Text("to")

                    Picker("End", selection: $scheduleEndHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Days")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach([(1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")], id: \.0) { day, label in
                            DayToggle(
                                label: label,
                                isSelected: scheduleDays.contains(day)
                            ) {
                                if scheduleDays.contains(day) {
                                    scheduleDays.remove(day)
                                } else {
                                    scheduleDays.insert(day)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func loadProfile() {
        guard let profile else { return }

        name = profile.name
        selectedIcon = profile.icon
        selectedColor = profile.color
        includeTags = profile.includeTags
        excludeTags = profile.excludeTags
        scheduleEnabled = profile.scheduleEnabled
        scheduleStartHour = profile.scheduleStartHour
        scheduleEndHour = profile.scheduleEndHour
        scheduleDays = Set(profile.scheduleDays)
    }

    private func save() {
        if let profile {
            // Update existing
            profile.name = name
            profile.icon = selectedIcon
            profile.color = selectedColor
            profile.includeTags = includeTags
            profile.excludeTags = excludeTags
            profile.scheduleEnabled = scheduleEnabled
            profile.scheduleStartHour = scheduleStartHour
            profile.scheduleEndHour = scheduleEndHour
            profile.scheduleDays = Array(scheduleDays)
            manager.updateProfile(profile)
        } else {
            // Create new
            let newProfile = FocusProfile(
                name: name,
                icon: selectedIcon,
                color: selectedColor,
                includeTags: includeTags,
                excludeTags: excludeTags
            )
            newProfile.scheduleEnabled = scheduleEnabled
            newProfile.scheduleStartHour = scheduleStartHour
            newProfile.scheduleEndHour = scheduleEndHour
            newProfile.scheduleDays = Array(scheduleDays)
            manager.createProfile(newProfile)
        }

        dismiss()
    }

    private func addIncludeTag() {
        let tag = newIncludeTag.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty, !includeTags.contains(tag) else { return }
        includeTags.append(tag)
        newIncludeTag = ""
    }

    private func addExcludeTag() {
        let tag = newExcludeTag.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty, !excludeTags.contains(tag) else { return }
        excludeTags.append(tag)
        newExcludeTag = ""
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }

    private func colorFromString(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "purple": return .purple
        case "orange": return .orange
        case "yellow": return .yellow
        case "pink": return .pink
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

// MARK: - Supporting Views

private struct TagChip: View {
    let tag: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.caption)

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

private struct DayToggle: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 28, height: 28)
                .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let maxX = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxX && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}
