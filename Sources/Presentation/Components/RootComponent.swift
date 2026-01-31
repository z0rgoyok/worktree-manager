import Foundation
import DecomposeKit

@MainActor
final class RootComponent: ObservableObject {
    @Published private(set) var childStack: ChildStack<Child>
    @Published var sheetSlot = ChildSlot<Sheet>()

    let workspace: WorkspaceComponent
    let settings: SettingsComponent
    let activityCenter: ActivityCenter

    typealias Effect = WorkspaceComponent.Effect

    private let effectsEmitter = EffectEmitter<WorkspaceComponent.Effect>()
    var effects: AsyncStream<WorkspaceComponent.Effect> { effectsEmitter.stream }

    enum Child: Equatable {
        case workspace
        case settings
        case help
    }

    enum Sheet: Identifiable, Equatable {
        case addRepository
        case addWorktree
        case createPR(worktreePath: String)
        case completeWorktree(worktreePath: String)

        var id: String {
            switch self {
            case .addRepository: return "addRepository"
            case .addWorktree: return "addWorktree"
            case .createPR(let path): return "createPR:\(path)"
            case .completeWorktree(let path): return "completeWorktree:\(path)"
            }
        }
    }

    static func makeDefault(loadOnInit: Bool = true) -> RootComponent {
        let store = AppStore.makeDefault(loadOnInit: loadOnInit)
        return RootComponent(store: store)
    }

    init(store: AppStore) {
        self.activityCenter = store.activityCenter
        self.workspace = WorkspaceComponent(store: store)
        self.settings = SettingsComponent(store: store)
        self.childStack = ChildStack(root: .workspace)

        Task { [weak self] in
            guard let self else { return }
            for await effect in self.workspace.effects {
                self.effectsEmitter.emit(effect)
            }
        }
    }

    func send(_ action: Action) {
        switch action {
        case .presentSheet(let sheet):
            sheetSlot.child = sheet
        case .dismissSheet:
            sheetSlot.child = nil
        case .selectChild(let child):
            switch child {
            case .workspace:
                childStack = ChildStack(root: .workspace)
            case .settings:
                childStack = ChildStack(root: .settings)
            case .help:
                childStack = ChildStack(root: .help)
            }
        }
    }

    enum Action: Equatable {
        case presentSheet(Sheet)
        case dismissSheet
        case selectChild(Child)
    }
}
