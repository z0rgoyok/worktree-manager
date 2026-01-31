import SwiftUI

struct ButtonExplanation: View {
    let label: String
    let icon: String
    let style: ButtonStyleType
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Mock button
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .cornerRadius(6)
            .frame(width: 100, alignment: .leading)

            Text(description)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .bordered: return Color(nsColor: .controlBackgroundColor)
        case .borderedGreen: return .green.opacity(0.2)
        case .prominent: return .accentColor
        case .prominentGreen: return .green
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .bordered: return .primary
        case .borderedGreen: return .green
        case .prominent, .prominentGreen: return .white
        }
    }
}

