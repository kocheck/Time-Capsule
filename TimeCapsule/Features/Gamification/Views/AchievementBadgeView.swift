import SwiftUI

/// Displays a single achievement badge
struct AchievementBadgeView: View {
    let achievement: Achievement
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 40
            case .large: return 60
            }
        }

        var frameSize: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 60
            case .large: return 90
            }
        }
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(achievement.isUnlocked ? categoryColor.opacity(0.2) : Color.secondary.opacity(0.1))

            // Icon
            Image(systemName: achievement.icon)
                .font(.system(size: size.iconSize))
                .foregroundStyle(achievement.isUnlocked ? categoryColor : .secondary.opacity(0.3))

            // Progress ring for locked achievements
            if !achievement.isUnlocked && achievement.progress > 0 {
                Circle()
                    .trim(from: 0, to: achievement.progressPercentage)
                    .stroke(categoryColor.opacity(0.5), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: size.frameSize, height: size.frameSize)
        .help(achievement.name)
    }

    private var categoryColor: Color {
        switch achievement.category {
        case .productivity: return .blue
        case .streaks: return .orange
        case .milestones: return .green
        case .special: return .purple
        }
    }
}

/// Full achievement card with details
struct AchievementCardView: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 16) {
            AchievementBadgeView(achievement: achievement, size: .medium)

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(.headline)
                    .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)

                Text(achievement.achievementDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !achievement.isUnlocked {
                    ProgressView(value: achievement.progressPercentage)
                        .tint(categoryColor)

                    Text("\(achievement.progress)/\(achievement.requirement)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if let unlockDate = achievement.unlockedAt {
                    Text("Unlocked \(unlockDate, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var categoryColor: Color {
        switch achievement.category {
        case .productivity: return .blue
        case .streaks: return .orange
        case .milestones: return .green
        case .special: return .purple
        }
    }
}

/// Unlock notification popup
struct AchievementUnlockPopup: View {
    let event: AchievementUnlockEvent
    var onDismiss: () -> Void

    @State private var isShowing = false

    var body: some View {
        VStack(spacing: 16) {
            // Confetti/celebration icon
            Image(systemName: "party.popper.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)

            Text("Achievement Unlocked!")
                .font(.headline)

            AchievementBadgeView(achievement: event.achievement, size: .large)

            Text(event.achievement.name)
                .font(.title2)
                .fontWeight(.bold)

            Text(event.achievement.achievementDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("+\(event.xpAwarded) XP")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.2))
                .foregroundStyle(.green)
                .clipShape(Capsule())

            if event.leveledUp, let newLevel = event.newLevel {
                Text("Level Up! You're now level \(newLevel)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Button("Awesome!") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
        .scaleEffect(isShowing ? 1 : 0.5)
        .opacity(isShowing ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isShowing = true
            }
        }
    }
}
