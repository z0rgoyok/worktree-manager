import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Close button header
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.borderless)
                .focusable(false)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal)
            .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text("Worktree Manager")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Quick Reference Guide")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 8)

                // What is Worktree
                HelpSection(title: "What is a Git Worktree?", icon: "arrow.triangle.branch") {
                    Text("Git worktree allows you to check out multiple branches simultaneously in separate directories. Instead of stashing changes or committing incomplete work to switch branches, you can have each branch in its own folder.")

                    HelpTip(text: "Use worktrees when you need to work on multiple features or fix bugs while keeping your main work untouched.")
                }

                Divider()

                // Workflow
                HelpSection(title: "Typical Workflow", icon: "arrow.right.circle") {
                    WorkflowStep(number: 1, title: "Create Worktree", description: "Click + to create a new worktree with a new or existing branch")
                    WorkflowStep(number: 2, title: "Work", description: "Open in your editor, make changes, commit")
                    WorkflowStep(number: 3, title: "Push", description: "Push your commits to remote")
                    WorkflowStep(number: 4, title: "Create PR", description: "Create a pull request for review")
                    WorkflowStep(number: 5, title: "Finish", description: "After PR is merged, clean up the worktree")
                }

                Divider()

                // Status Indicators
                HelpSection(title: "Status Indicators", icon: "circle.fill") {
                    StatusExplanation(
                        icon: "pencil.circle.fill",
                        color: .orange,
                        title: "Modified",
                        description: "You have uncommitted changes in this worktree"
                    )
                    StatusExplanation(
                        icon: "arrow.up.circle.fill",
                        color: .blue,
                        title: "N to push",
                        description: "You have N commits that haven't been pushed to remote"
                    )
                    StatusExplanation(
                        icon: "arrow.down.circle.fill",
                        color: .purple,
                        title: "N behind",
                        description: "Remote has N commits you don't have locally"
                    )
                    StatusExplanation(
                        icon: "icloud.slash",
                        color: .secondary,
                        title: "Not pushed",
                        description: "Branch has never been pushed to remote"
                    )
                }

                Divider()

                // PR Status
                HelpSection(title: "Pull Request Status", icon: "arrow.triangle.pull") {
                    StatusExplanation(
                        icon: "arrow.triangle.pull",
                        color: .green,
                        title: "PR #N (Open)",
                        description: "Pull request is open and awaiting review/merge"
                    )
                    StatusExplanation(
                        icon: "checkmark.circle.fill",
                        color: .purple,
                        title: "PR #N (Merged)",
                        description: "Pull request was merged — ready to clean up"
                    )
                    StatusExplanation(
                        icon: "xmark.circle.fill",
                        color: .red,
                        title: "PR #N (Closed)",
                        description: "Pull request was closed without merging"
                    )
                }

                Divider()

                // Buttons
                HelpSection(title: "Action Buttons", icon: "hand.tap") {
                    ButtonExplanation(
                        label: "Push",
                        icon: "arrow.up",
                        style: .bordered,
                        description: "Push commits to remote. Disabled if nothing to push."
                    )
                    ButtonExplanation(
                        label: "Create PR",
                        icon: "arrow.triangle.pull",
                        style: .bordered,
                        description: "Create a new pull request on GitHub/GitLab"
                    )
                    ButtonExplanation(
                        label: "PR #N",
                        icon: "arrow.triangle.pull",
                        style: .borderedGreen,
                        description: "Open existing pull request in browser"
                    )
                    ButtonExplanation(
                        label: "Complete",
                        icon: "checkmark.circle",
                        style: .prominentGreen,
                        description: "Complete worktree: cleanup after PR merge, merge locally, or discard. Options to delete local/remote branches."
                    )
                    ButtonExplanation(
                        label: "Open",
                        icon: "arrow.up.forward.app",
                        style: .prominent,
                        description: "Open worktree in your preferred code editor"
                    )
                }

                Divider()

                // Menu Actions
                HelpSection(title: "Menu Actions (⋯)", icon: "ellipsis.circle") {
                    MenuItemExplanation(icon: "folder", title: "Show in Finder", description: "Open worktree folder in Finder")
                    MenuItemExplanation(icon: "terminal", title: "Open in Terminal", description: "Open Terminal at worktree path")
                    MenuItemExplanation(icon: "arrow.clockwise", title: "Refresh Status", description: "Reload git status for this worktree")
                    MenuItemExplanation(icon: "lock", title: "Lock / Unlock", description: "Lock prevents 'git worktree remove' and 'git worktree prune' from deleting this worktree. Useful when worktree is on external drive or network share that may be temporarily unavailable.")
                    MenuItemExplanation(icon: "checkmark.circle", title: "Complete Worktree", description: "Finish work: merge locally, cleanup after PR, or discard. Delete local/remote branches.")
                }

                Divider()

                // Badges
                HelpSection(title: "Worktree Badges", icon: "tag") {
                    BadgeExplanation(text: "main", color: .blue, description: "Primary worktree (the original repo clone). Cannot be removed.")
                    BadgeExplanation(text: "locked", color: .orange, description: "Worktree is locked to prevent accidental deletion")
                    BadgeExplanation(text: "prunable", color: .red, description: "Worktree directory is missing or corrupt. Safe to remove.")
                }

                Divider()

                // Tips
                HelpSection(title: "Tips", icon: "lightbulb") {
                    HelpTip(text: "Press ⌘R to refresh the worktree list")
                    HelpTip(text: "Click on PR badge to open it in browser")
                    HelpTip(text: "Use 'Finish' button when PR is merged to clean up properly")
                    HelpTip(text: "Lock important worktrees to prevent accidental deletion")
                }

                    Spacer(minLength: 20)
                }
                .padding(24)
            }
        }
        .frame(width: 550, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Help Components

struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(.leading, 4)
        }
    }
}

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

struct WorkflowStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(.blue))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct StatusExplanation: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

enum ButtonStyleType {
    case bordered, borderedGreen, prominent, prominentGreen
}

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

struct MenuItemExplanation: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

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

#Preview {
    HelpView()
}
