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

    public var connectionStatusLabel: String {
        switch self {
        case let .localAuthFile(path):
            let normalizedPath = path.lowercased()
            if normalizedPath.contains("opencode") {
                return "Connected via OpenCode"
            }
            if normalizedPath.contains("/.codex/") || normalizedPath.contains("/codex/") {
                return "Connected via Codex CLI"
            }
            return "Connected via local auth file"
        case .oauthKeychain:
            return "Connected via OpenAI OAuth"
        }
    }
}
