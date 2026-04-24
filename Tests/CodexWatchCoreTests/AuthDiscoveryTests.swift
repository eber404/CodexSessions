import XCTest
@testable import CodexWatchCore

final class AuthDiscoveryTests: XCTestCase {
    func testDiscoveryPrefersCustomPathOverFallbacks() throws {
        let fileManager = FakeFileManager(existingPaths: [
            "/tmp/auth.json",
            "/Users/test/.codex/auth.json",
        ])
        let source = try AuthDiscovery(fileManager: fileManager, environment: [:]).resolve(preferredPath: "/tmp/auth.json")

        XCTAssertEqual(source, .localAuthFile(path: "/tmp/auth.json"))
    }

    func testDiscoveryFindsCodexDefaultPath() throws {
        let path = "/Users/test/.codex/auth.json"
        let fileManager = FakeFileManager(existingPaths: [path])
        let source = try AuthDiscovery(fileManager: fileManager, environment: ["HOME": "/Users/test"]).resolve(preferredPath: nil)

        XCTAssertEqual(source, .localAuthFile(path: path))
    }

    func testDiscoveryFindsOpenCodeLocalSharePath() throws {
        let path = "/Users/test/.local/share/opencode/auth.json"
        let fileManager = FakeFileManager(existingPaths: [path])
        let source = try AuthDiscovery(fileManager: fileManager, environment: ["HOME": "/Users/test"]).resolve(preferredPath: nil)

        XCTAssertEqual(source, .localAuthFile(path: path))
    }

    func testDiscoveryFallsBackToOauthWhenNoFiles() throws {
        let fileManager = FakeFileManager(existingPaths: [])
        let source = try AuthDiscovery(fileManager: fileManager, environment: ["HOME": "/Users/test"]).resolve(preferredPath: nil)

        XCTAssertEqual(source, .oauthKeychain(service: KeychainTokenStore.serviceName, account: KeychainTokenStore.defaultAccount))
    }
}
