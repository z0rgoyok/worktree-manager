import SwiftUI

struct HelpTip: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundStyle(.yellow)

            Text(text)
                .font(.callout)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(Color.yellow.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
