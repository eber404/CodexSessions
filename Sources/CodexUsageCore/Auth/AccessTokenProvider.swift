import Foundation

public enum AccessTokenProviderError: Error {
    case fileReadFailed
    case missingAccessToken
    case refreshTokenMissing
}

public protocol AccessTokenProviding: Sendable {
    func accessToken(for source: AuthSource) async throws -> String
}

public protocol OAuthTokenRefreshing: Sendable {
    func refreshAccessToken(refreshToken: String) async throws -> OAuthTokenRecord
}

public struct NoopTokenRefresher: OAuthTokenRefreshing {
    public init() {}

    public func refreshAccessToken(refreshToken _: String) async throws -> OAuthTokenRecord {
        throw AccessTokenProviderError.refreshTokenMissing
    }
}

public struct AccessTokenProvider: AccessTokenProviding {
    private let tokenStore: TokenStore
    private let refresher: OAuthTokenRefreshing

    public init(tokenStore: TokenStore = KeychainTokenStore(), refresher: OAuthTokenRefreshing = NoopTokenRefresher()) {
        self.tokenStore = tokenStore
        self.refresher = refresher
    }

    public func accessToken(for source: AuthSource) async throws -> String {
        switch source {
        case let .localAuthFile(path):
            return try parseToken(fromAuthFile: path)
        case let .oauthKeychain(_, account):
            guard var record = try tokenStore.loadTokenRecord(account: account) else {
                throw AccessTokenProviderError.missingAccessToken
            }

            if shouldRefresh(record) {
                guard let refreshToken = record.refreshToken, !refreshToken.isEmpty else {
                    throw AccessTokenProviderError.refreshTokenMissing
                }
                let refreshed = try await refresher.refreshAccessToken(refreshToken: refreshToken)
                record = OAuthTokenRecord(
                    accessToken: refreshed.accessToken,
                    refreshToken: refreshed.refreshToken ?? record.refreshToken,
                    expiresAt: refreshed.expiresAt,
                    accountId: refreshed.accountId ?? record.accountId
                )
                try tokenStore.saveTokenRecord(record, account: account)
            }

            guard !record.accessToken.isEmpty else {
                throw AccessTokenProviderError.missingAccessToken
            }
            return record.accessToken
        }
    }

    private func shouldRefresh(_ record: OAuthTokenRecord) -> Bool {
        guard let expiresAt = record.expiresAt else { return false }
        return expiresAt <= Int(Date().timeIntervalSince1970) + 60
    }

    private func parseToken(fromAuthFile path: String) throws -> String {
        guard let data = FileManager.default.contents(atPath: path) else {
            throw AccessTokenProviderError.fileReadFailed
        }

        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else {
            throw AccessTokenProviderError.missingAccessToken
        }

        if let token = dictionary["access_token"] as? String, !token.isEmpty {
            return token
        }
        if let token = dictionary["id_token"] as? String, !token.isEmpty {
            return token
        }
        if let credentials = dictionary["credentials"] as? [String: Any],
           let token = credentials["access_token"] as? String,
           !token.isEmpty {
            return token
        }

        if let openAI = dictionary["openai"] as? [String: Any],
           let token = openAI["access"] as? String,
           !token.isEmpty {
            return token
        }

        throw AccessTokenProviderError.missingAccessToken
    }
}
