import Foundation

enum CommandEnvironment {
    static func forCommandExecution(base: [String: String] = ProcessInfo.processInfo.environment) -> [String: String] {
        var environment = base

        let existingPaths = (environment["PATH"] ?? "")
            .split(separator: ":", omittingEmptySubsequences: true)
            .map(String.init)

        var mergedPaths: [String] = existingPaths

        // These are typically available even in GUI-launched apps with a minimal environment.
        let systemFallbackPaths = [
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin",
        ]

        // Common locations for tools installed by package managers on macOS.
        let packageManagerPaths = [
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/usr/local/bin",
            "/usr/local/sbin",
            "/opt/local/bin",
            "/opt/local/sbin",
        ]

        for path in systemFallbackPaths + packageManagerPaths where !mergedPaths.contains(path) {
            mergedPaths.append(path)
        }

        environment["PATH"] = mergedPaths.joined(separator: ":")
        return environment
    }
}

