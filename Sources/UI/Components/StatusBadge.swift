import SwiftUI

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(DS.Typography.badge)
            .foregroundStyle(color)
            .padding(.horizontal, DS.Spacing.xxs)
            .padding(.vertical, 1)
            .background(color.opacity(0.15))
            .cornerRadius(DS.Radius.xs)
    }
}

