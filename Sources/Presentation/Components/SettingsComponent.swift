import Foundation
import Combine

@MainActor
final class SettingsComponent: ObservableObject {
    struct State: Equatable {
        var worktreeBasePath: String = ""
        var defaultEditorId: String = ""
        var defaultCopyPatterns: [CopyPattern] = []
        var availableEditors: [Editor] = []
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

    func setDefaultEditorId(_ newValue: String) {
        store.setDefaultEditorId(newValue)
    }

    func setDefaultCopyPatterns(_ newValue: [CopyPattern]) {
        store.setDefaultCopyPatterns(newValue)
    }

    private func bindStore() {
        store.$worktreeBasePath
            .sink { [weak self] in self?.state.worktreeBasePath = $0 }
            .store(in: &cancellables)

        store.$defaultEditorId
            .sink { [weak self] in self?.state.defaultEditorId = $0 }
            .store(in: &cancellables)

        store.$defaultCopyPatterns
            .sink { [weak self] in self?.state.defaultCopyPatterns = $0 }
            .store(in: &cancellables)

        state.availableEditors = store.availableEditors()
    }
}

