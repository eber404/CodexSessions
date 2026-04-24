import Foundation

public enum AccessTokenProviderError: Error {
    case fileReadFailed
    case missingAccessToken
    case refreshTokenMissing
    case expiredAccessToken
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

        var token: String?

        if let t = dictionary["access_token"] as? String, !t.isEmpty {
            token = t
        } else if let t = dictionary["id_token"] as? String, !t.isEmpty {
            token = t
        } else if let credentials = dictionary["credentials"] as? [String: Any],
                  let t = credentials["access_token"] as? String, !t.isEmpty {
            token = t
        } else if let openAI = dictionary["openai"] as? [String: Any],
                  let t = openAI["access"] as? String, !t.isEmpty {
            token = t
        } else if let tokens = dictionary["tokens"] as? [String: Any],
                  let t = tokens["access_token"] as? String, !t.isEmpty {
            token = t
        }

        guard let accessToken = token else {
            throw AccessTokenProviderError.missingAccessToken
        }

        if isTokenExpired(accessToken) {
            throw AccessTokenProviderError.expiredAccessToken
        }

        return accessToken
    }

    private func isTokenExpired(_ token: String) -> Bool {
        let parts = token.split(separator: ".")
        guard parts.count >= 2,
              let payloadData = Data(base64Encoded: String(parts[1]).base64Padded()) else {
            return false
        }

        guard let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            return false
        }

        return exp <= Date().timeIntervalSince1970
    }
}

private extension String {
    func base64Padded() -> String {
        let remainder = count % 4
        if remainder > 0 {
            return self + String(repeating: "=", count: 4 - remainder)
        }
        return self
    }
}
