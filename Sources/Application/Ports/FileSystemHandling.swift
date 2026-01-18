import Foundation

protocol FileSystemHandling {
    func fileExists(atPath path: String) -> Bool
    func isDirectory(atPath path: String) -> Bool
    func createDirectory(atPath path: String, withIntermediateDirectories: Bool) throws
    func copyItem(atPath srcPath: String, toPath dstPath: String) throws
    func fileSize(atPath path: String) -> Int64?
    func directorySize(atPath path: String) -> Int64?
}

