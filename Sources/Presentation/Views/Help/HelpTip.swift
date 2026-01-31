import SwiftUI

struct HelpTip: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .font(.caption)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(8)
    }
}

