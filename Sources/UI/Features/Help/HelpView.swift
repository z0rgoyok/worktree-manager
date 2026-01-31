import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var visibleSection: HelpSection = .overview

    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient
            HelpHeader(dismiss: dismiss)

            // Single scrollable content with nav bar inside
            ScrollViewReader { proxy in
                // Navigation tabs (clickable + auto-highlight)
                HelpNavBar(
                    visibleSection: visibleSection,
                    proxy: proxy
                )

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                        // Overview
                        OverviewContent()
                            .id(HelpSection.overview)
                            .background(SectionVisibilityTracker(section: .overview))

                        SectionDivider()

                        // Status
                        StatusContent()
                            .id(HelpSection.status)
                            .background(SectionVisibilityTracker(section: .status))

                        SectionDivider()

                        // Actions
                        ActionsContent()
                            .id(HelpSection.actions)
                            .background(SectionVisibilityTracker(section: .actions))

                        SectionDivider()

                        // Shortcuts
                        ShortcutsContent()
                            .id(HelpSection.shortcuts)
                            .background(SectionVisibilityTracker(section: .shortcuts))

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, DS.Spacing.xxl)
                    .padding(.top, DS.Spacing.lg)
                }
                .onPreferenceChange(VisibleSectionPreferenceKey.self) { section in
                    if let section {
                        withAnimation(DS.Animation.quick) {
                            visibleSection = section
                        }
                    }
                }
                .onChange(of: visibleSection) { _, newSection in
                    // This is triggered by tab clicks, not scroll
                }
                .coordinateSpace(name: "scroll")
            }
        }
        .frame(width: 700, height: 720)
        .background(DS.Colors.surfacePrimary)
    }
}

// MARK: - Help Section Enum

enum HelpSection: String, CaseIterable {
    case overview = "Overview"
    case status = "Status & Badges"
    case actions = "Actions"
    case shortcuts = "Shortcuts"

    var icon: String {
        switch self {
        case .overview: return "book.pages"
        case .status: return "circle.fill"
        case .actions: return "hand.tap"
        case .shortcuts: return "command"
        }
    }
}

// MARK: - Visible Section Tracking

private struct VisibleSectionPreferenceKey: PreferenceKey {
    static var defaultValue: HelpSection? = nil

    static func reduce(value: inout HelpSection?, nextValue: () -> HelpSection?) {
        value = value ?? nextValue()
    }
}

private struct SectionVisibilityTracker: View {
    let section: HelpSection

    var body: some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .named("scroll"))
            let isVisible = frame.minY < 150 && frame.maxY > 100

            Color.clear
                .preference(
                    key: VisibleSectionPreferenceKey.self,
                    value: isVisible ? section : nil
                )
        }
    }
}

// MARK: - Section Divider

private struct SectionDivider: View {
    var body: some View {
        Divider()
            .padding(.vertical, DS.Spacing.xl)
    }
}

// MARK: - Header

private struct HelpHeader: View {
    let dismiss: DismissAction

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(0.1),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 100)

            HStack(alignment: .center) {
                // Icon
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60)

                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text("Worktree Manager")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Quick Reference Guide")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

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
            .padding(.horizontal, DS.Spacing.xxl)
        }
        .frame(height: 100)
    }
}

// MARK: - Navigation Bar

private struct HelpNavBar: View {
    let visibleSection: HelpSection
    let proxy: ScrollViewProxy

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            ForEach(HelpSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(DS.Animation.standard) {
                        proxy.scrollTo(section, anchor: .top)
                    }
                } label: {
                    HStack(spacing: DS.Spacing.xs) {
                        Image(systemName: section.icon)
                            .font(.caption)
                        Text(section.rawValue)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(
                        visibleSection == section
                            ? DS.Colors.accent.opacity(0.15)
                            : Color.clear
                    )
                    .foregroundStyle(
                        visibleSection == section
                            ? DS.Colors.accent
                            : DS.Colors.textSecondary
                    )
                    .cornerRadius(DS.Radius.sm)
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
        }
        .padding(.horizontal, DS.Spacing.xxl)
        .padding(.vertical, DS.Spacing.md)
        .background(DS.Colors.surfaceSecondary.opacity(0.5))
    }
}

// MARK: - Overview Content

private struct OverviewContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxl) {
            // Section title
            SectionTitle(title: "Overview", icon: "book.pages")

            // What is Git Worktree
            HelpSectionBlock(title: "What is a Git Worktree?", icon: "arrow.triangle.branch") {
                Text("Git worktree allows you to check out multiple branches simultaneously in separate directories. Instead of stashing changes or committing incomplete work to switch branches, you can have each branch in its own folder.")
                    .foregroundStyle(.secondary)

                HelpTip(text: "Use worktrees when you need to work on multiple features or fix bugs while keeping your main work untouched.")
            }

            // Workflow
            HelpSectionBlock(title: "Typical Workflow", icon: "arrow.right.circle") {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    WorkflowStep(number: 1, title: "Create Worktree", description: "Use ⌘N or context menu to create a new worktree")
                    WorkflowStep(number: 2, title: "Work", description: "Open in your editor (⌘O), make changes, commit")
                    WorkflowStep(number: 3, title: "Push", description: "Push commits to remote (⌘⇧P)")
                    WorkflowStep(number: 4, title: "Create PR", description: "Create a pull request via context menu")
                    WorkflowStep(number: 5, title: "Finish", description: "After PR is merged, finish the worktree to clean up")
                }
            }

            // Tips
            HelpSectionBlock(title: "Pro Tips", icon: "lightbulb") {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    HelpTip(text: "Right-click any worktree for quick actions")
                    HelpTip(text: "Lock important worktrees to prevent accidental deletion")
                    HelpTip(text: "Use 'Finish Worktree' when PR is merged to clean up properly")
                }
            }
        }
    }
}

// MARK: - Status Content

private struct StatusContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxl) {
            SectionTitle(title: "Status & Badges", icon: "circle.fill")

            // Git Status
            HelpSectionBlock(title: "Git Status Indicators", icon: "circle.fill") {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    StatusExplanation(
                        icon: "pencil.circle.fill",
                        color: .orange,
                        title: "Modified",
                        description: "Uncommitted changes in this worktree"
                    )
                    StatusExplanation(
                        icon: "arrow.up.circle.fill",
                        color: .blue,
                        title: "N to push",
                        description: "Local commits not yet pushed to remote"
                    )
                    StatusExplanation(
                        icon: "arrow.down.circle.fill",
                        color: .purple,
                        title: "N behind",
                        description: "Remote has commits you don't have locally"
                    )
                    StatusExplanation(
                        icon: "icloud.slash",
                        color: .secondary,
                        title: "Not pushed",
                        description: "Branch has never been pushed to remote"
                    )
                    StatusExplanation(
                        icon: "checkmark.circle",
                        color: .secondary,
                        title: "Clean",
                        description: "No uncommitted changes, in sync with remote"
                    )
                }
            }

            // PR Status
            HelpSectionBlock(title: "Pull Request Status", icon: "arrow.triangle.pull") {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
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
            }

            // Badges
            HelpSectionBlock(title: "Worktree Badges", icon: "tag") {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    BadgeExplanation(
                        text: "main",
                        color: .blue,
                        description: "Primary worktree (original repo clone). Cannot be removed."
                    )
                    HStack(alignment: .center, spacing: DS.Spacing.md) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .frame(width: 70, alignment: .leading)
                        Text("Worktree is locked to prevent accidental deletion")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Actions Content

private struct ActionsContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxl) {
            SectionTitle(title: "Actions", icon: "hand.tap")

            // Context Menu
            HelpSectionBlock(title: "Context Menu", icon: "contextualmenu.and.cursorarrow") {
                Text("Right-click any worktree to access these actions:")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, DS.Spacing.sm)

                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    MenuItemExplanation(
                        icon: "arrow.up.forward.app",
                        title: "Open in Editor",
                        description: "Open worktree in your preferred code editor (⌘O)"
                    )
                    MenuItemExplanation(
                        icon: "ellipsis.rectangle",
                        title: "Open in...",
                        description: "Choose from multiple configured editors"
                    )
                }
            }

            HelpSectionBlock(title: "Navigation", icon: "folder") {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    MenuItemExplanation(
                        icon: "arrow.up.forward.app",
                        title: "Open in Editor",
                        description: "Open worktree in your preferred code editor (⌘O)"
                    )
                    MenuItemExplanation(
                        icon: "folder",
                        title: "Show in Finder",
                        description: "Open worktree folder in Finder (⌘⇧F)"
                    )
                    MenuItemExplanation(
                        icon: "terminal",
                        title: "Open in Terminal",
                        description: "Open Terminal at worktree path (⌘⇧T)"
                    )
                    MenuItemExplanation(
                        icon: "doc.on.doc",
                        title: "Copy Path",
                        description: "Copy worktree path to clipboard (⌘⇧C)"
                    )
                }
            }

            HelpSectionBlock(title: "Git Operations", icon: "arrow.triangle.branch") {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    MenuItemExplanation(
                        icon: "arrow.up",
                        title: "Push",
                        description: "Push commits to remote (⌘⇧P)"
                    )
                    MenuItemExplanation(
                        icon: "arrow.down",
                        title: "Pull",
                        description: "Pull latest changes from remote (⌘⌥P)"
                    )
                    MenuItemExplanation(
                        icon: "arrow.clockwise",
                        title: "Refresh Status",
                        description: "Reload git status for this worktree (⌘R)"
                    )
                }
            }

            HelpSectionBlock(title: "Pull Requests", icon: "arrow.triangle.pull") {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    MenuItemExplanation(
                        icon: "plus.circle",
                        title: "Create Pull Request...",
                        description: "Open dialog to create a new PR on GitHub/GitLab"
                    )
                    MenuItemExplanation(
                        icon: "arrow.up.right.square",
                        title: "View PR / View Merged PR",
                        description: "Open existing pull request in browser"
                    )
                }
            }

            HelpSectionBlock(title: "Worktree Management", icon: "gearshape") {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    MenuItemExplanation(
                        icon: "lock",
                        title: "Lock / Unlock",
                        description: "Lock prevents accidental deletion. Useful for worktrees on external drives."
                    )
                    MenuItemExplanation(
                        icon: "checkmark.circle",
                        title: "Finish Worktree...",
                        description: "Complete workflow: merge locally, cleanup after PR, or discard"
                    )
                    MenuItemExplanation(
                        icon: "plus",
                        title: "New Worktree...",
                        description: "Create a new worktree with a new or existing branch (⌘N)"
                    )
                }
            }
        }
    }
}

// MARK: - Shortcuts Content

private struct ShortcutsContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxl) {
            SectionTitle(title: "Shortcuts", icon: "command")

            HelpSectionBlock(title: "Global", icon: "globe") {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    ShortcutRow(keys: "⌘ N", action: "New Worktree")
                    ShortcutRow(keys: "⌘ R", action: "Refresh Status")
                    ShortcutRow(keys: "⌘ ,", action: "Open Settings")
                    ShortcutRow(keys: "⌘ ?", action: "Show Help")
                }
            }

            HelpSectionBlock(title: "Worktree Actions", icon: "rectangle.stack") {
                Text("When a worktree is selected:")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, DS.Spacing.sm)

                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    ShortcutRow(keys: "⌘ O", action: "Open in Editor")
                    ShortcutRow(keys: "⌘ ⇧ F", action: "Show in Finder")
                    ShortcutRow(keys: "⌘ ⇧ T", action: "Open in Terminal")
                    ShortcutRow(keys: "⌘ ⇧ C", action: "Copy Path")
                }
            }

            HelpSectionBlock(title: "Git Operations", icon: "arrow.triangle.branch") {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    ShortcutRow(keys: "⌘ ⇧ P", action: "Push")
                    ShortcutRow(keys: "⌘ ⌥ P", action: "Pull")
                }
            }

            HelpSectionBlock(title: "Navigation", icon: "arrow.up.arrow.down") {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    ShortcutRow(keys: "↑ / ↓", action: "Navigate worktrees")
                    ShortcutRow(keys: "⏎", action: "Open selected worktree")
                    ShortcutRow(keys: "⎋", action: "Close dialogs")
                }
            }
        }
    }
}

// MARK: - Section Title

private struct SectionTitle: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(DS.Colors.accent)
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding(.bottom, DS.Spacing.sm)
    }
}

// MARK: - Help Section Block (renamed from HelpSection to avoid conflict)

private struct HelpSectionBlock<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: 20)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                content
            }
            .padding(.leading, DS.Spacing.xxl + DS.Spacing.xs)
        }
    }
}

// MARK: - Shortcut Row

private struct ShortcutRow: View {
    let keys: String
    let action: String

    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xxs)
                .background(DS.Colors.surfaceSecondary)
                .cornerRadius(DS.Radius.xs)
                .frame(width: 100, alignment: .center)

            Text(action)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

#Preview {
    HelpView()
}
