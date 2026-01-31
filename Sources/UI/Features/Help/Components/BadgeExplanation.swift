import SwiftUI

struct BadgeExplanation: View {
    let text: String
    let color: Color
    let description: String

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.md) {
            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xxs)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .cornerRadius(DS.Radius.xs)
                .frame(width: 70, alignment: .leading)

            Text(description)
                .font(.callout)
                .foregroundStyle(DS.Colors.textSecondary)
        }
    }
}
