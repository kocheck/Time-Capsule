import Foundation
import SwiftData
import Combine

/// Manages focus profiles and filters tasks accordingly
@Observable
class FocusProfileManager {
    private let modelContext: ModelContext
    private var scheduleTimer: Timer?

    var profiles: [FocusProfile] = []
    var activeProfile: FocusProfile?
    var isAutoSwitchEnabled = true

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadProfiles()
            startScheduleMonitor()
        }
    }

    deinit {
        scheduleTimer?.invalidate()
    }

    // MARK: - Profile Management

    /// Loads all profiles from the database
    func loadProfiles() async {
        let descriptor = FetchDescriptor<FocusProfile>(
            sortBy: [SortDescriptor(\.createdAt)]
        )

        profiles = (try? modelContext.fetch(descriptor)) ?? []

        // Set active profile
        activeProfile = profiles.first { $0.isActive }

        // Create default profiles if none exist
        if profiles.isEmpty {
            await createDefaultProfiles()
        }
    }

    /// Creates default profiles for new users
    func createDefaultProfiles() async {
        for profile in FocusProfile.defaultProfiles() {
            modelContext.insert(profile)
        }
        try? modelContext.save()
        await loadProfiles()
    }

    /// Creates a new profile
    func createProfile(_ profile: FocusProfile) {
        modelContext.insert(profile)
        try? modelContext.save()
        profiles.append(profile)
    }

    /// Updates an existing profile
    func updateProfile(_ profile: FocusProfile) {
        try? modelContext.save()
    }

    /// Deletes a profile
    func deleteProfile(_ profile: FocusProfile) {
        if activeProfile?.id == profile.id {
            deactivateCurrentProfile()
        }
        modelContext.delete(profile)
        try? modelContext.save()
        profiles.removeAll { $0.id == profile.id }
    }

    // MARK: - Activation

    /// Activates a profile
    func activateProfile(_ profile: FocusProfile) {
        // Deactivate all other profiles
        for p in profiles {
            p.isActive = false
        }

        profile.isActive = true
        activeProfile = profile
        try? modelContext.save()
    }

    /// Deactivates the current profile
    func deactivateCurrentProfile() {
        activeProfile?.isActive = false
        activeProfile = nil
        try? modelContext.save()
    }

    /// Toggles a profile's active state
    func toggleProfile(_ profile: FocusProfile) {
        if profile.isActive {
            deactivateCurrentProfile()
        } else {
            activateProfile(profile)
        }
    }

    // MARK: - Task Filtering

    /// Filters tasks based on the active profile
    func filterTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        guard let profile = activeProfile else {
            return tasks
        }

        return tasks.filter { profile.matches($0) }
    }

    /// Checks if a task should be shown with the current profile
    func shouldShowTask(_ task: TaskItem) -> Bool {
        guard let profile = activeProfile else {
            return true
        }

        return profile.matches(task)
    }

    // MARK: - Schedule Monitoring

    /// Starts monitoring for scheduled profile switches
    func startScheduleMonitor() {
        // Check every minute for schedule changes
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkScheduledProfiles()
        }

        // Also check immediately
        checkScheduledProfiles()
    }

    /// Checks if any profile should be auto-activated based on schedule
    func checkScheduledProfiles() {
        guard isAutoSwitchEnabled else { return }

        // Find a profile that should be active now
        for profile in profiles where profile.scheduleEnabled {
            if profile.shouldBeActiveNow() {
                // Only switch if not already active
                if activeProfile?.id != profile.id {
                    activateProfile(profile)
                }
                return
            }
        }

        // If no scheduled profile matches and current has schedule, deactivate
        if let current = activeProfile, current.scheduleEnabled, !current.shouldBeActiveNow() {
            deactivateCurrentProfile()
        }
    }

    /// Forces a schedule check
    func refreshSchedule() {
        checkScheduledProfiles()
    }
}

// MARK: - macOS Focus Mode Integration

#if os(macOS)
import AppKit

extension FocusProfileManager {
    /// Attempts to sync with macOS Focus Mode
    /// Note: This requires proper entitlements and user permission
    func syncWithSystemFocusMode() {
        // macOS Focus Mode integration would go here
        // This requires the com.apple.developer.focus-status entitlement
        // and user permission to access Focus status
    }
}
#endif
