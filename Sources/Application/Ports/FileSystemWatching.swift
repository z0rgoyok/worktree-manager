import Foundation

protocol FileSystemWatching {
    func setChangeHandler(_ handler: @escaping (_ changedPaths: Set<String>) -> Void)
    func updateWatchedPaths(_ paths: Set<String>)
}
