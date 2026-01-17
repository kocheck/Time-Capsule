import SwiftUI

/// Compact profile selector for quick switching
struct ProfileSelectorView: View {
    @Bindable var manager: FocusProfileManager
    @State private var showEditor = false
    @State private var editingProfile: FocusProfile?

    var body: some View {
        Menu {
            // Current profile indicator
            if let active = manager.activeProfile {
                Label("Active: \(active.name)", systemImage: active.icon)
                    .disabled(true)
                Divider()
            }

            // Profile list
            ForEach(manager.profiles) { profile in
                Button {
                    manager.toggleProfile(profile)
                } label: {
                    HStack {
                        Label(profile.name, systemImage: profile.icon)
                        if profile.isActive {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            // Turn off
            Button {
                manager.deactivateCurrentProfile()
            } label: {
                Label("No Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
            .disabled(manager.activeProfile == nil)

            Divider()

            // Edit profiles
            Button {
                showEditor = true
            } label: {
                Label("Edit Profiles...", systemImage: "slider.horizontal.3")
            }
        } label: {
            HStack(spacing: 4) {
                if let active = manager.activeProfile {
                    Image(systemName: active.icon)
                        .foregroundStyle(profileColor(active.color))
                    Text(active.name)
                } else {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("All Tasks")
                }
            }
            .font(.caption)
        }
        .sheet(isPresented: $showEditor) {
            ProfileListView(manager: manager)
        }
    }

    private func profileColor(_ colorName: String) -> Color {
        switch colorName {
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

// MARK: - Profile List View

struct ProfileListView: View {
    @Bindable var manager: FocusProfileManager
    @State private var showNewProfile = false
    @State private var editingProfile: FocusProfile?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Auto-switch profiles", isOn: $manager.isAutoSwitchEnabled)
                        .help("Automatically activate profiles based on schedule")
                }

                Section("Profiles") {
                    ForEach(manager.profiles) { profile in
                        ProfileRowView(profile: profile, manager: manager) {
                            editingProfile = profile
                        }
                    }
                    .onDelete(perform: deleteProfiles)
                }

                Section {
                    Button {
                        showNewProfile = true
                    } label: {
                        Label("New Profile", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Focus Profiles")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showNewProfile) {
                ProfileEditorView(manager: manager, profile: nil)
            }
            .sheet(item: $editingProfile) { profile in
                ProfileEditorView(manager: manager, profile: profile)
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }

    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            manager.deleteProfile(manager.profiles[index])
        }
    }
}

// MARK: - Profile Row

private struct ProfileRowView: View {
    let profile: FocusProfile
    let manager: FocusProfileManager
    let onEdit: () -> Void

    var body: some View {
        HStack {
            // Icon and name
            Label(profile.name, systemImage: profile.icon)
                .foregroundStyle(profile.isActive ? profileColor : .primary)

            Spacer()

            // Schedule indicator
            if profile.scheduleEnabled {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Tags count
            let tagCount = profile.includeTags.count + profile.excludeTags.count
            if tagCount > 0 {
                Text("\(tagCount) tags")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Active indicator
            if profile.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .contextMenu {
            Button {
                manager.toggleProfile(profile)
            } label: {
                Label(profile.isActive ? "Deactivate" : "Activate", systemImage: profile.isActive ? "xmark" : "checkmark")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
    }

    private var profileColor: Color {
        switch profile.color {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "purple": return .purple
        case "orange": return .orange
        default: return .blue
        }
    }
}
