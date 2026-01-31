import SwiftUI

struct BadgeExplanation: View {
    let text: String
    let color: Color
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.2))
                .foregroundStyle(color)
                .cornerRadius(4)
                .frame(width: 70, alignment: .leading)

            Text(description)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

