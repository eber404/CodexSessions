public enum AuthSource: Equatable, Sendable {
    case localAuthFile(path: String)
    case oauthKeychain(service: String, account: String)

    public var sourceLabel: String {
        switch self {
        case .localAuthFile:
            return "Local Auth"
        case .oauthKeychain:
            return "OAuth"
        }
    }
}
