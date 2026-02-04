import SwiftUI

struct StatusExplanation: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
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
