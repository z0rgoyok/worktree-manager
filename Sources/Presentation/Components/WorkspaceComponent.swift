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
        case openURL(URL)
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
            root?.send(.presentSheet(.help))
        case .refresh:
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await self.store.refreshWorktrees()
                } catch {
                    self.effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
                }
            }
        case .setSidebarSelection(let selection):
            Task { [weak self] in
                guard let self else { return }
                await self.applySidebarSelection(selection)
            }
        }
    }

    func addRepository(at path: String) async {
        do {
            try await store.addRepository(at: path)
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
    }

    func createWorktree(
        name: String,
        branch: String,
        createNewBranch: Bool,
        baseBranch: String?,
        copyPatterns: [CopyPattern]?
    ) async {
        do {
            try await store.createWorktree(
                name: name,
                branch: branch,
                createNewBranch: createNewBranch,
                baseBranch: baseBranch,
                copyPatterns: copyPatterns
            )
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
    }

    func recreateBranchAndWorktree(name: String, branch: String, baseBranch: String, copyPatterns: [CopyPattern]?) async {
        do {
            try await store.recreateBranchAndWorktree(name: name, branch: branch, baseBranch: baseBranch, copyPatterns: copyPatterns)
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
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

    func loadWorktreesOnly(for repo: Repository) async -> [Worktree] {
        await store.loadWorktreesOnly(for: repo)
    }

    func statusCell(for worktreePath: String) -> WorktreeStatusCell {
        store.statusStore.cell(forWorktreePath: worktreePath)
    }

    func selectWorktree(_ worktree: Worktree?) {
        store.selectedWorktree = worktree
        state.selectedWorktree = worktree
    }

    func removeRepository(_ repo: Repository) async {
        await store.removeRepository(repo)
    }

    func completeWorktree(_ worktree: Worktree, options: CompleteWorktreeOptions) async {
        do {
            try await store.completeWorktree(worktree, options: options)
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
    }

    func loadHasRemoteBranch(for worktree: Worktree) async -> Bool {
        await store.loadHasRemoteBranch(for: worktree)
    }

    func openInFinder(_ worktree: Worktree) {
        store.openInFinder(worktree)
    }

    func openInTerminal(_ worktree: Worktree) {
        store.openInTerminal(worktree)
    }

    func openInEditor(_ worktree: Worktree) {
        do {
            try store.openInEditor(worktree)
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
    }

    func openInEditor(_ worktree: Worktree, editor: Editor) {
        do {
            try store.openInEditor(worktree, editor: editor)
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
    }

    func configuredEditors() -> [Editor] {
        store.configuredEditors
    }

    var rememberEditorChoice: Bool {
        get { store.rememberEditorChoice }
        set {
            objectWillChange.send()
            store.rememberEditorChoice = newValue
        }
    }

    func preferredEditor(for worktree: Worktree) -> Editor? {
        store.preferredEditor(for: worktree)
    }

    func setPreferredEditor(_ editor: Editor, for worktree: Worktree) {
        store.setPreferredEditor(editor, for: worktree)
    }

    func clearPreferredEditor(for worktree: Worktree) {
        store.clearPreferredEditor(for: worktree)
    }

    /// Opens worktree in editor, using remembered editor if available
    func smartOpenInEditor(_ worktree: Worktree) {
        if rememberEditorChoice, let editor = preferredEditor(for: worktree) {
            openInEditor(worktree, editor: editor)
        } else {
            openInEditor(worktree)
        }
    }

    /// Opens worktree in specific editor and optionally remembers choice
    func openInEditorAndRemember(_ worktree: Worktree, editor: Editor) {
        if rememberEditorChoice {
            setPreferredEditor(editor, for: worktree)
        }
        openInEditor(worktree, editor: editor)
    }

    func loadExpandedRepositoryIds() -> Set<UUID> {
        store.preferences.expandedRepositoryIds
    }

    func setExpandedRepositoryIds(_ ids: Set<UUID>) {
        store.preferences.expandedRepositoryIds = ids
    }

    func push(_ worktree: Worktree) async {
        do {
            try await store.push(worktree)
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
    }

    func pull(_ worktree: Worktree) async {
        do {
            try await store.pull(worktree)
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
    }

    func refreshWorktreeStatus(_ worktree: Worktree) async {
        await store.refreshWorktreeStatus(worktree)
    }

    func createPR(_ worktree: Worktree, title: String, body: String, baseBranch: String?) async {
        do {
            let url = try await store.createPR(worktree, title: title, body: body, baseBranch: baseBranch)
            effectsEmitter.emit(.openURL(url))
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
    }

    func openPR(_ worktree: Worktree) {
        if let url = store.openPRURL(worktree) {
            effectsEmitter.emit(.openURL(url))
        }
    }

    func mergeBranch(_ worktree: Worktree, into targetBranch: String) async {
        do {
            try await store.mergeBranch(worktree, into: targetBranch)
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
    }

    func lockWorktree(_ worktree: Worktree) async {
        do {
            try await store.lockWorktree(worktree)
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
    }

    func unlockWorktree(_ worktree: Worktree) async {
        do {
            try await store.unlockWorktree(worktree)
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
    }

    func pruneWorktrees() async {
        do {
            try await store.pruneWorktrees()
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
    }

    func removeWorktree(_ worktree: Worktree, force: Bool = false, deleteBranch: Bool = false) async {
        do {
            try await store.removeWorktree(worktree, force: force, deleteBranch: deleteBranch)
        } catch {
            effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
        }
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
            do {
                try await store.selectRepository(selection.repository)
            } catch {
                effectsEmitter.emit(.showAlert(title: "Error", message: error.localizedDescription))
                return
            }
        }

        if case .worktree(let wt, _) = selection {
            store.selectedWorktree = wt
        } else {
            store.selectedWorktree = nil
        }
    }
}
