import XCTest
@testable import CodexUsageCore

final class AuthSourceTests: XCTestCase {
    func testConnectionStatusLabelUsesOpenCodeForOpenCodePaths() {
        let source = AuthSource.localAuthFile(path: "/Users/test/.config/opencode/auth.json")

        XCTAssertEqual(source.connectionStatusLabel, "Connected via OpenCode")
    }

    func testConnectionStatusLabelUsesCodexCLIForCodexPaths() {
        let source = AuthSource.localAuthFile(path: "/Users/test/.codex/auth.json")

        XCTAssertEqual(source.connectionStatusLabel, "Connected via Codex CLI")
    }

    func testConnectionStatusLabelUsesLocalAuthFallbackForUnknownPath() {
        let source = AuthSource.localAuthFile(path: "/tmp/auth.json")

        XCTAssertEqual(source.connectionStatusLabel, "Connected via local auth file")
    }

    func testConnectionStatusLabelUsesOAuthForKeychainSource() {
        let source = AuthSource.oauthKeychain(service: "svc", account: "acc")

        XCTAssertEqual(source.connectionStatusLabel, "Connected via OpenAI OAuth")
    }
}
