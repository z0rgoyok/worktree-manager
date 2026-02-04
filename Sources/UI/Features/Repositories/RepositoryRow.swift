import SwiftUI

struct RepositoryRow: View {
    let repository: Repository
    
    private var isArchived: Bool {
        repository.isArchived
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .foregroundStyle(isArchived ? DS.Colors.textTertiary : .blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(repository.name)
                    .fontWeight(.medium)
                    .foregroundStyle(isArchived ? DS.Colors.textSecondary : DS.Colors.textPrimary)

                Text(repository.path)
                    .font(.caption)
                    .foregroundStyle(isArchived ? DS.Colors.textQuaternary : DS.Colors.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.vertical, 4)
    }
}
