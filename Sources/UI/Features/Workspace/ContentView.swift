import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var root: RootComponent
    @EnvironmentObject var workspace: WorkspaceComponent
    @EnvironmentObject var activityCenter: ActivityCenter
    @State private var alert: AlertState?

    var body: some View {
        splitView
            .frame(minWidth: 900, minHeight: 550)
            .navigationTitle(navigationTitle)
            .toolbar { toolbarContent }
            .sheet(item: sheetBinding) { SheetContent(sheet: $0, worktreeLookup: worktree(for:)) }
            .alert(alert?.title ?? "", isPresented: alertIsPresented) {
                Button("OK") { alert = nil }
            } message: {
                Text(alert?.message ?? "")
            }
            .task {
                for await effect in root.effects {
                    switch effect {
                    case .showAlert(let title, let message):
                        alert = AlertState(title: title, message: message)
                    case .openURL(let url):
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            .animation(DS.Animation.quick, value: activityCenter.currentGlobal)
    }

    private var splitView: some View {
        NavigationSplitView {
            ProjectTreeSidebar(selection: sidebarSelectionBinding)
                .frame(minWidth: DS.Sizes.sidebarMinWidth)
                .navigationSplitViewColumnWidth(
                    min: DS.Sizes.sidebarMinWidth,
                    ideal: DS.Sizes.sidebarIdealWidth,
                    max: DS.Sizes.sidebarMaxWidth
                )
        } detail: {
            KanbanBoard(selection: workspace.state.sidebarSelection)
                .frame(minWidth: 600)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if workspace.state.selectedRepository != nil {
                Button {
                    root.send(.presentSheet(.addWorktree))
                } label: {
                    Label("New Worktree", systemImage: "plus.square.on.square")
                }
                .help("New Worktree... (⌘N)")

                if let selectedWorktree = workspace.state.selectedWorktree {
                    OpenEditorMenu(root: root, workspace: workspace, worktree: selectedWorktree)
                        .help("Open in Editor (⌘O)")

                    Button {
                        workspace.openInFinder(selectedWorktree)
                    } label: {
                        Label("Finder", systemImage: "folder")
                    }
                    .help("Show in Finder (⇧⌘F)")

                    Button {
                        workspace.openInTerminal(selectedWorktree)
                    } label: {
                        Label("Terminal", systemImage: "terminal")
                    }
                    .help("Open in Terminal (⇧⌘T)")
                }

                Button {
                    workspace.send(.refresh, root: root)
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Refresh (⌘R)")
            }
        }

        ToolbarItem(placement: .status) {
            if let activity = activityCenter.currentGlobal {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text(activity.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .transition(.opacity)
            }
        }
    }

    private var navigationTitle: String {
        if let worktree = workspace.state.selectedWorktree {
            return worktree.name
        } else if let repo = workspace.state.selectedRepository {
            return repo.name
        }
        return "Worktree Manager"
    }

    private var sidebarSelectionBinding: Binding<SidebarSelection?> {
        Binding(
            get: { workspace.state.sidebarSelection },
            set: { newSelection in
                workspace.send(.setSidebarSelection(newSelection), root: root)
            }
        )
    }

    private var sheetBinding: Binding<RootComponent.Sheet?> {
        Binding(
            get: { root.sheetSlot.child },
            set: { newValue in
                if newValue == nil {
                    root.send(.dismissSheet)
                } else {
                    root.sheetSlot.child = newValue
                }
            }
        )
    }

    private var alertIsPresented: Binding<Bool> {
        Binding(
            get: { alert != nil },
            set: { isPresented in
                if !isPresented {
                    alert = nil
                }
            }
        )
    }

    private func worktree(for path: String) -> Worktree? {
        if let selected = workspace.state.selectedWorktree, selected.path == path {
            return selected
        }
        return workspace.state.worktrees.first { $0.path == path }
    }

    private struct SheetContent: View {
        let sheet: RootComponent.Sheet
        let worktreeLookup: (String) -> Worktree?

        @EnvironmentObject private var workspace: WorkspaceComponent

        var body: some View {
            switch sheet {
            case .addRepository:
                AddRepositorySheet()
            case .addWorktree:
                AddWorktreeSheet()
            case .createPR(let worktreePath):
                if let worktree = worktreeLookup(worktreePath) {
                    CreatePRSheet(worktree: worktree)
                } else {
                    VStack(spacing: 8) {
                        Text("Worktree not found")
                            .font(.headline)
                        Text(worktreePath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            case .completeWorktree(let worktreePath):
                if let worktree = worktreeLookup(worktreePath) {
                    CompleteWorktreeSheet(
                        worktree: worktree,
                        statusCell: workspace.statusCell(for: worktree.path)
                    )
                } else {
                    VStack(spacing: 8) {
                        Text("Worktree not found")
                            .font(.headline)
                        Text(worktreePath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            case .configureEditors:
                ConfigureEditorsSheet()
            case .help:
                HelpView()
            }
        }
    }
}

#Preview {
    let root = RootComponent.makeDefault(loadOnInit: false)
    return ContentView()
        .environmentObject(root)
        .environmentObject(root.workspace)
        .environmentObject(root.activityCenter)
}

private struct AlertState {
    let title: String
    let message: String
}
