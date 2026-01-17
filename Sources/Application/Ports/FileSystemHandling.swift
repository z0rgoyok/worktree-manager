import Foundation

protocol FileSystemHandling {
    func fileExists(atPath path: String) -> Bool
    func createDirectory(atPath path: String, withIntermediateDirectories: Bool) throws
}

