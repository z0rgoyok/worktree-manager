import SwiftUI

struct MenuItemExplanation: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(DS.Colors.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(DS.Colors.textPrimary)

                Text(description)
                    .font(.callout)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
        }
    }
}
