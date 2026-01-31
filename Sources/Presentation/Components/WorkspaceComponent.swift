import Foundation
import Combine
import DecomposeKit

@MainActor
final class WorkspaceComponent: ObservableObject {
    struct State: Equatable {
        var repositories: [Repository] = []
        var selectedRepository: Repository?
        var selectedWorktree: Worktree?
        var worktrees: [Worktree] = []
        var branches: [String] = []
        var worktreeBasePath: String = ""
        var sidebarSelection: SidebarSelection?
    }

    enum Effect: Equatable {
        case showAlert(title: String, message: String)
    }

    enum Action: Equatable {
        case presentAddRepository
        case presentAddWorktree
        case presentCreatePR(worktreePath: String)
        case presentCompleteWorktree(worktreePath: String)
        case presentHelp
        case refresh
        case setSidebarSelection(SidebarSelection?)
    }

    @Published private(set) var state = State()

    private let effectsEmitter = EffectEmitter<Effect>()
    var effects: AsyncStream<Effect> { effectsEmitter.stream }

    private let store: AppStore
    private var cancellables: Set<AnyCancellable> = []

    init(store: AppStore) {
        self.store = store
        bindStore()
    }

    func send(_ action: Action, root: RootComponent? = nil) {
        switch action {
        case .presentAddRepository:
            root?.send(.presentSheet(.addRepository))
        case .presentAddWorktree:
            root?.send(.presentSheet(.addWorktree))
        case .presentCreatePR(let worktreePath):
            root?.send(.presentSheet(.createPR(worktreePath: worktreePath)))
        case .presentCompleteWorktree(let worktreePath):
            root?.send(.presentSheet(.completeWorktree(worktreePath: worktreePath)))
        case .presentHelp:
            root?.send(.selectChild(.help))
        case .refresh:
            Task { [weak self] in
                guard let self else { return }
                await self.store.refreshWorktrees()
            }
        case .setSidebarSelection(let selection):
            Task { [weak self] in
                guard let self else { return }
                await self.applySidebarSelection(selection)
            }
        }
    }

    func addRepository(at path: String) async {
        await store.addRepository(at: path)
    }

    func createWorktree(
        name: String,
        branch: String,
        createNewBranch: Bool,
        baseBranch: String?,
        copyPatterns: [CopyPattern]?
    ) async {
        await store.createWorktree(
            name: name,
            branch: branch,
            createNewBranch: createNewBranch,
            baseBranch: baseBranch,
            copyPatterns: copyPatterns
        )
    }

    func recreateBranchAndWorktree(name: String, branch: String, baseBranch: String, copyPatterns: [CopyPattern]?) async {
        await store.recreateBranchAndWorktree(name: name, branch: branch, baseBranch: baseBranch, copyPatterns: copyPatterns)
    }

    func loadBranches() async {
        await store.loadBranches()
    }

    func branchExists(_ branch: String) -> Bool {
        store.branchExists(branch)
    }

    func preferredBaseBranch() -> String? {
        store.preferredBaseBranch()
    }

    func setPreferredBaseBranch(_ branch: String) {
        store.setPreferredBaseBranch(branch)
    }

    func loadCopyPreview(for repo: Repository) async -> [CopyPreviewItem] {
        await store.loadCopyPreview(for: repo)
    }

    func statusCell(for worktreePath: String) -> WorktreeStatusCell {
        store.statusStore.cell(forWorktreePath: worktreePath)
    }

    func openInFinder(_ worktree: Worktree) {
        store.openInFinder(worktree)
    }

    func openInTerminal(_ worktree: Worktree) {
        store.openInTerminal(worktree)
    }

    func openInEditor(_ worktree: Worktree) {
        store.openInEditor(worktree)
    }

    func openInEditor(_ worktree: Worktree, editor: Editor) {
        store.openInEditor(worktree, editor: editor)
    }

    func configuredEditors() -> [Editor] {
        store.configuredEditors
    }

    func push(_ worktree: Worktree) async {
        await store.push(worktree)
    }

    func pull(_ worktree: Worktree) async {
        await store.pull(worktree)
    }

    func refreshWorktreeStatus(_ worktree: Worktree) async {
        await store.refreshWorktreeStatus(worktree)
    }

    func createPR(_ worktree: Worktree, title: String, body: String, baseBranch: String?) async {
        await store.createPR(worktree, title: title, body: body, baseBranch: baseBranch)
    }

    func openPR(_ worktree: Worktree) {
        store.openPR(worktree)
    }

    func mergeBranch(_ worktree: Worktree, into targetBranch: String) async {
        await store.mergeBranch(worktree, into: targetBranch)
    }

    func lockWorktree(_ worktree: Worktree) async {
        await store.lockWorktree(worktree)
    }

    func unlockWorktree(_ worktree: Worktree) async {
        await store.unlockWorktree(worktree)
    }

    func pruneWorktrees() async {
        await store.pruneWorktrees()
    }

    func removeWorktree(_ worktree: Worktree, force: Bool = false, deleteBranch: Bool = false) async {
        await store.removeWorktree(worktree, force: force, deleteBranch: deleteBranch)
    }

    private func bindStore() {
        store.$repositories
            .sink { [weak self] in self?.state.repositories = $0 }
            .store(in: &cancellables)

        store.$selectedRepository
            .sink { [weak self] in self?.state.selectedRepository = $0 }
            .store(in: &cancellables)

        store.$selectedWorktree
            .sink { [weak self] in self?.state.selectedWorktree = $0 }
            .store(in: &cancellables)

        store.$worktrees
            .sink { [weak self] in self?.state.worktrees = $0 }
            .store(in: &cancellables)

        store.$branches
            .sink { [weak self] in self?.state.branches = $0 }
            .store(in: &cancellables)

        store.$worktreeBasePath
            .sink { [weak self] in self?.state.worktreeBasePath = $0 }
            .store(in: &cancellables)

        // Bridge application-level error state into presentation effects.
        store.$showError
            .removeDuplicates()
            .sink { [weak self] isPresented in
                guard let self else { return }
                guard isPresented else { return }
                let message = self.store.error ?? "Unknown error"
                self.effectsEmitter.emit(.showAlert(title: "Error", message: message))
                self.store.clearError()
            }
            .store(in: &cancellables)

        // Mirror initial selection to UI selection.
        if let repo = store.selectedRepository {
            state.sidebarSelection = .repository(repo)
        }
    }

    private func applySidebarSelection(_ selection: SidebarSelection?) async {
        state.sidebarSelection = selection

        guard let selection else {
            store.selectedWorktree = nil
            return
        }

        if store.selectedRepository?.id != selection.repository.id {
            await store.selectRepository(selection.repository)
        }

        if case .worktree(let wt, _) = selection {
            store.selectedWorktree = wt
        } else {
            store.selectedWorktree = nil
        }
    }
}
