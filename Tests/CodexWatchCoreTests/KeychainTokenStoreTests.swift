import XCTest
@testable import CodexWatchCore

final class KeychainTokenStoreTests: XCTestCase {
    func testPrefersKeychainOauthWhenNoLocalAuthExists() throws {
        let resolver = AuthResolver(
            discovery: AuthDiscovery(fileManager: FakeFileManager(existingPaths: []), environment: ["HOME": "/Users/test"]),
            tokenStore: InMemoryTokenStore(tokens: ["access-token"])
        )

        XCTAssertEqual(try resolver.resolve(preferredPath: nil), .oauthKeychain(service: KeychainTokenStore.serviceName, account: KeychainTokenStore.defaultAccount))
    }
}

private struct InMemoryTokenStore: TokenStore {
    var tokens: [String]

    func loadAccessToken(account: String) throws -> String? {
        tokens.first
    }

    func saveAccessToken(_ token: String, account: String) throws {}

    func removeAccessToken(account: String) throws {}

    func loadTokenRecord(account: String) throws -> OAuthTokenRecord? {
        guard let token = tokens.first else { return nil }
        return OAuthTokenRecord(accessToken: token, refreshToken: nil, expiresAt: nil, accountId: nil)
    }

    func saveTokenRecord(_ record: OAuthTokenRecord, account: String) throws {}
}
