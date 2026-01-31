import SwiftUI

struct BlockingProgressOverlay: View {
    let title: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.06)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                ProgressView()
                    .controlSize(.regular)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .transition(.opacity)
    }
}

