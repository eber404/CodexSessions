@testable import CodexUsageCore

struct FakeFileManager: FileManaging {
    let existingPaths: Set<String>

    init(existingPaths: [String]) {
        self.existingPaths = Set(existingPaths)
    }

    func fileExists(atPath path: String) -> Bool {
        existingPaths.contains(path)
    }
}
