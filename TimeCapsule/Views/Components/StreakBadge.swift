import SwiftUI

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: streakIcon)
                .foregroundColor(streakColor)
            Text("\(streak)")
                .font(.headline)
                .foregroundColor(streakColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(streakColor.opacity(0.2))
        .cornerRadius(16)
    }

    private var streakIcon: String {
        if streak >= 7 {
            return "flame.fill"
        } else if streak >= 3 {
            return "flame"
        } else {
            return "clock"
        }
    }

    private var streakColor: Color {
        if streak >= 7 {
            return .orange
        } else if streak >= 3 {
            return .yellow
        } else {
            return .gray
        }
    }
}
