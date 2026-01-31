import Foundation
import Combine

@MainActor
final class SettingsComponent: ObservableObject {
    struct State: Equatable {
        var worktreeBasePath: String = ""
        var defaultCopyPatterns: [CopyPattern] = []
    }

    @Published private(set) var state = State()

    private let store: AppStore
    private var cancellables: Set<AnyCancellable> = []

    init(store: AppStore) {
        self.store = store
        bindStore()
    }

    func setWorktreeBasePath(_ newValue: String) {
        store.setWorktreeBasePath(newValue)
    }

    func setDefaultCopyPatterns(_ newValue: [CopyPattern]) {
        store.setDefaultCopyPatterns(newValue)
    }

    func copyPatterns(for repo: Repository) -> [CopyPattern]? {
        store.copyPatterns(for: repo)
    }

    func setCopyPatterns(_ patterns: [CopyPattern], for repo: Repository) {
        store.setCopyPatterns(patterns, for: repo)
    }

    func removeCopyPatterns(for repo: Repository) {
        store.removeCopyPatterns(for: repo)
    }

    private func bindStore() {
        store.$worktreeBasePath
            .sink { [weak self] in self?.state.worktreeBasePath = $0 }
            .store(in: &cancellables)

        store.$defaultCopyPatterns
            .sink { [weak self] in self?.state.defaultCopyPatterns = $0 }
            .store(in: &cancellables)
    }
}
