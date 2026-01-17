import Foundation
import CoreServices

/// Monitors file system directories for changes using FSEvents (recursive)
final class FileSystemWatcher {
    private var stream: FSEventStreamRef?
    private var watchedPaths: Set<String> = []
    private var onChange: ((Set<String>) -> Void)?

    /// Debounce mechanism to avoid multiple rapid callbacks
    private var debounceWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 0.3
    private var pendingChangedPaths: Set<String> = []

    deinit {
        stop()
    }

    /// Sets the callback to invoke when any watched directory changes
    func setChangeHandler(_ handler: @escaping (Set<String>) -> Void) {
        self.onChange = handler
    }

    /// Updates watched paths to match the given set
    func updateWatchedPaths(_ paths: Set<String>) {
        // Filter to only existing paths
        let existingPaths = paths.filter { FileManager.default.fileExists(atPath: $0) }

        guard existingPaths != watchedPaths else { return }

        watchedPaths = existingPaths
        restartStream()
    }

    private func restartStream() {
        stop()

        guard !watchedPaths.isEmpty else { return }

        let pathsToWatch = watchedPaths.map { $0 as CFString } as CFArray

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { (
            streamRef,
            clientCallbackInfo,
            numEvents,
            eventPaths,
            eventFlags,
            eventIds
        ) in
            guard let info = clientCallbackInfo else { return }
            let watcher = Unmanaged<FileSystemWatcher>.fromOpaque(info).takeUnretainedValue()
            watcher.handleChange(eventPaths: eventPaths)
        }

        stream = FSEventStreamCreate(
            nil,
            callback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.2, // latency in seconds
            UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        )

        guard let stream = stream else { return }

        FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .utility))
        FSEventStreamStart(stream)
    }

    private func stop() {
        guard let stream = stream else { return }

        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
        debounceWorkItem?.cancel()
        pendingChangedPaths.removeAll()
    }

    private func handleChange(eventPaths: UnsafeMutableRawPointer?) {
        if let paths = extractPaths(eventPaths: eventPaths) {
            pendingChangedPaths.formUnion(paths)
        }

        // Debounce: cancel previous pending callback
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let changed = self.pendingChangedPaths
            self.pendingChangedPaths.removeAll()
            DispatchQueue.main.async {
                self.onChange?(changed)
            }
        }

        debounceWorkItem = workItem
        DispatchQueue.global(qos: .utility).asyncAfter(
            deadline: .now() + debounceInterval,
            execute: workItem
        )
    }

    private func extractPaths(eventPaths: UnsafeMutableRawPointer?) -> Set<String>? {
        guard let eventPaths else { return nil }
        // With kFSEventStreamCreateFlagUseCFTypes, eventPaths is a CFArray of CFString.
        let cfArray = unsafeBitCast(eventPaths, to: CFArray.self)
        let array = cfArray as NSArray
        var paths = Set<String>()
        for case let path as String in array {
            paths.insert(path)
        }
        return paths.isEmpty ? nil : paths
    }
}
