import Foundation

public struct AuthDiscovery {
    private let fileManager: FileManaging
    private let environment: [String: String]

    public init(fileManager: FileManaging = FileManager.default, environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.fileManager = fileManager
        self.environment = environment
    }

    public func resolve(preferredPath: String?) throws -> AuthSource {
        if let preferredPath, fileManager.fileExists(atPath: preferredPath) {
            return .localAuthFile(path: preferredPath)
        }

        for path in candidatePaths() where fileManager.fileExists(atPath: path) {
            return .localAuthFile(path: path)
        }

        return .oauthKeychain(service: KeychainTokenStore.serviceName, account: KeychainTokenStore.defaultAccount)
    }

    private func candidatePaths() -> [String] {
        let home = environment["HOME", default: NSHomeDirectory()]

        var paths: [String] = []
        if let codexHome = environment["CODEX_HOME"], !codexHome.isEmpty {
            paths.append("\(codexHome)/auth.json")
        }
        paths.append("\(home)/.codex/auth.json")

        if let openCodeHome = environment["OPENCODE_HOME"], !openCodeHome.isEmpty {
            paths.append("\(openCodeHome)/auth.json")
        }
        paths.append("\(home)/.config/opencode/auth.json")

        if let xdgDataHome = environment["XDG_DATA_HOME"], !xdgDataHome.isEmpty {
            paths.append("\(xdgDataHome)/opencode/auth.json")
        }
        paths.append("\(home)/.local/share/opencode/auth.json")

        return paths
    }
}

public struct AuthResolver {
    private let discovery: AuthDiscovery
    private let tokenStore: TokenStore

    public init(discovery: AuthDiscovery = AuthDiscovery(), tokenStore: TokenStore = KeychainTokenStore()) {
        self.discovery = discovery
        self.tokenStore = tokenStore
    }

    public func resolve(preferredPath: String?) throws -> AuthSource {
        let source = try discovery.resolve(preferredPath: preferredPath)
        switch source {
        case .localAuthFile:
            return source
        case let .oauthKeychain(service, account):
            if try tokenStore.loadAccessToken(account: account) != nil {
                return .oauthKeychain(service: service, account: account)
            }
            return .oauthKeychain(service: service, account: account)
        }
    }
}
