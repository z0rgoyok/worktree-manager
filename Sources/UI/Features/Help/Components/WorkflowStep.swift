import SwiftUI

struct WorkflowStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )

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
