import Foundation
import XCTest
@testable import CodexUsageCore

final class AccessTokenProviderTests: XCTestCase {
    func testAccessTokenProviderRefreshesExpiredOauthToken() async throws {
        let expiredRecord = OAuthTokenRecord(
            accessToken: "old-token",
            refreshToken: "refresh-token",
            expiresAt: 1,
            accountId: "acct_old"
        )

        let refreshedRecord = OAuthTokenRecord(
            accessToken: "new-token",
            refreshToken: "refresh-token-2",
            expiresAt: Int(Date().timeIntervalSince1970) + 3600,
            accountId: "acct_new"
        )

        let store = InMemoryTokenStore(record: expiredRecord)
        let refresher = StubTokenRefresher(result: refreshedRecord)

        let provider = AccessTokenProvider(tokenStore: store, refresher: refresher)
        let token = try await provider.accessToken(for: .oauthKeychain(service: KeychainTokenStore.serviceName, account: KeychainTokenStore.defaultAccount))

        XCTAssertEqual(token, "new-token")
        XCTAssertEqual(store.record?.refreshToken, "refresh-token-2")
    }

    func testAccessTokenProviderReadsOpenCodeAuthJsonOpenAIAccessToken() async throws {
        let json = """
        {
          \"openai\": {
            \"type\": \"oauth\",
            \"access\": \"from-opencode-openai\"
          }
        }
        """

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("opencode-auth-\(UUID().uuidString).json")
        try json.data(using: .utf8)?.write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let provider = AccessTokenProvider()
        let token = try await provider.accessToken(for: .localAuthFile(path: fileURL.path))

        XCTAssertEqual(token, "from-opencode-openai")
    }
}

private final class InMemoryTokenStore: @unchecked Sendable, TokenStore {
    var record: OAuthTokenRecord?

    init(record: OAuthTokenRecord?) {
        self.record = record
    }

    func loadAccessToken(account: String) throws -> String? {
        record?.accessToken
    }

    func saveAccessToken(_ token: String, account: String) throws {
        var current = record ?? OAuthTokenRecord(accessToken: token, refreshToken: nil, expiresAt: nil, accountId: nil)
        current.accessToken = token
        record = current
    }

    func removeAccessToken(account: String) throws {
        record = nil
    }

    func loadTokenRecord(account: String) throws -> OAuthTokenRecord? {
        record
    }

    func saveTokenRecord(_ record: OAuthTokenRecord, account: String) throws {
        self.record = record
    }
}

private struct StubTokenRefresher: OAuthTokenRefreshing {
    let result: OAuthTokenRecord

    func refreshAccessToken(refreshToken: String) async throws -> OAuthTokenRecord {
        result
    }
}
