import SwiftUI

/// Skeleton loading card
struct KanbanCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            // Title skeleton
            RoundedRectangle(cornerRadius: DS.Radius.xs)
                .fill(DS.Colors.surfaceSecondary)
                .frame(height: 16)
                .frame(maxWidth: .infinity)
                .opacity(isAnimating ? 0.5 : 1)

            // Description skeleton
            RoundedRectangle(cornerRadius: DS.Radius.xs)
                .fill(DS.Colors.surfaceSecondary)
                .frame(height: 12)
                .frame(width: 180)
                .opacity(isAnimating ? 0.5 : 1)

            // Footer skeleton
            HStack {
                RoundedRectangle(cornerRadius: DS.Radius.xs)
                    .fill(DS.Colors.surfaceSecondary)
                    .frame(width: 60, height: 10)
                    .opacity(isAnimating ? 0.5 : 1)

                Spacer()
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
        .onAppear {
            withAnimation(
                Animation
                    .easeInOut(duration: 1)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

