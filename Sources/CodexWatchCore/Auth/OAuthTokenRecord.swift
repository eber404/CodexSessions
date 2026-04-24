public struct OAuthTokenRecord: Codable, Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String?
    public var expiresAt: Int?
    public var accountId: String?

    public init(accessToken: String, refreshToken: String?, expiresAt: Int?, accountId: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.accountId = accountId
    }
}
