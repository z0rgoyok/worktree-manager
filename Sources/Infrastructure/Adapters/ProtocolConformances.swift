import Foundation

extension GitService: GitClient {}
extension StorageService: PreferencesStore {}
extension EditorService: EditorOpening {}
extension FileSystemWatcher: FileSystemWatching {}

