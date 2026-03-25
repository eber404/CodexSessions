import Foundation

public protocol FileManaging {
    func fileExists(atPath path: String) -> Bool
}

extension FileManager: FileManaging {}
