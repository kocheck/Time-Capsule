import SwiftUI

/// Displays user's level and XP progress
struct LevelProgressView: View {
    let userLevel: UserLevel
    let streak: Streak?

    var body: some View {
        VStack(spacing: 16) {
            levelHeader
            progressBar
            statsRow
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var levelHeader: some View {
        HStack {
            // Level badge
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                Text("\(userLevel.currentLevel)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 2) {
                Text(userLevel.levelTitle)
                    .font(.headline)

                Text("Level \(userLevel.currentLevel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Streak indicator
            if let streak = streak, streak.isActive {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(streak.currentStreak)")
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * userLevel.levelProgress)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(userLevel.currentLevelXP) XP")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(userLevel.xpForNextLevel) XP needed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 24) {
            StatItem(value: "\(userLevel.totalXP)", label: "Total XP", icon: "star.fill", color: .yellow)
            StatItem(value: "\(userLevel.tasksCompleted)", label: "Tasks", icon: "checkmark.circle.fill", color: .green)
            StatItem(value: "\(userLevel.achievementsUnlocked)", label: "Badges", icon: "medal.fill", color: .purple)
        }
    }
}

private struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(value)
                    .fontWeight(.semibold)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

/// Compact level badge for menu bar
struct LevelBadgeView: View {
    let userLevel: UserLevel

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 20, height: 20)

                Text("\(userLevel.currentLevel)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            // Mini XP bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.purple)
                        .frame(width: geometry.size.width * userLevel.levelProgress)
                }
            }
            .frame(width: 40, height: 4)
        }
    }
}

/// Full achievements view
struct AchievementsView: View {
    let engine: AchievementEngine

    @State private var selectedCategory: AchievementCategory?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let level = engine.userLevel {
                        LevelProgressView(userLevel: level, streak: engine.streak)
                    }

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryButton(
                                title: "All",
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }

                            ForEach(AchievementCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }

                    // Achievements list
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCardView(achievement: achievement)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Achievements")
        }
    }

    private var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return engine.getAchievements(for: category)
        }
        return engine.achievements.sorted { a, b in
            if a.isUnlocked != b.isUnlocked {
                return a.isUnlocked
            }
            return a.progressPercentage > b.progressPercentage
        }
    }
}

private struct CategoryButton: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
