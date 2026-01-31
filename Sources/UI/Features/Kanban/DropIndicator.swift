import SwiftUI

struct DropIndicator: View {
    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(DS.Colors.accent)
                .frame(width: 8, height: 8)

            Rectangle()
                .fill(DS.Colors.accent)
                .frame(height: 2)

            Circle()
                .fill(DS.Colors.accent)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, DS.Spacing.xxs)
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }
}

