import CodexUsageCore
import Combine
import Foundation

protocol LoginItemManaging {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool)
}

extension LoginItemManager: LoginItemManaging {}

@MainActor
final class AppModel: ObservableObject {
    private enum PreferenceKey {
        static let refreshIntervalSeconds = "settings.refreshIntervalSeconds"
        static let launchAtLoginEnabled = "settings.launchAtLoginEnabled"
    }

    private static let defaultRefreshIntervalSeconds: TimeInterval = 300

    @Published var preferredAuthPath: String = ""
    @Published var refreshIntervalSeconds: TimeInterval = AppModel.defaultRefreshIntervalSeconds
    @Published var launchAtLoginEnabled: Bool = false
    @Published var showUsedInsteadOfRemaining: Bool = false
    @Published var activeSourceLabel: String = "Detecting..."
    @Published var authMessage: String?
    @Published var lastManualRefreshAt: Date?
    @Published var isSignedOut: Bool = false

    let tokenStore: KeychainTokenStore
    let coordinator: RefreshCoordinator

    private let oauthSession: OpenAIOAuthSession
    private let userDefaults: UserDefaults
    private let loginItemManager: LoginItemManaging
    private var sessionKeepAlive: SessionKeepAlive?

    init(
        tokenStore: KeychainTokenStore = KeychainTokenStore(),
        oauthSession: OpenAIOAuthSession = OpenAIOAuthSession(),
        userDefaults: UserDefaults = .standard,
        loginItemManager: LoginItemManaging = LoginItemManager()
    ) {
        self.tokenStore = tokenStore
        self.oauthSession = oauthSession
        self.userDefaults = userDefaults
        self.loginItemManager = loginItemManager
        self.coordinator = RefreshCoordinator(service: EmptyUsageService())
    }

    func start() {
        restoreUserSettings()
        rebuildServiceAndRefresh()
    }

    func restoreUserSettings() {
        let persistedInterval = userDefaults.double(forKey: PreferenceKey.refreshIntervalSeconds)
        refreshIntervalSeconds = persistedInterval > 0 ? persistedInterval : AppModel.defaultRefreshIntervalSeconds

        if userDefaults.object(forKey: PreferenceKey.launchAtLoginEnabled) == nil {
            launchAtLoginEnabled = loginItemManager.isEnabled
        } else {
            launchAtLoginEnabled = userDefaults.bool(forKey: PreferenceKey.launchAtLoginEnabled)
        }

        loginItemManager.setEnabled(launchAtLoginEnabled)
    }

    func updateRefreshInterval() {
        if !isSignedOut {
            coordinator.startAutoRefresh(interval: refreshIntervalSeconds)
        }
    }

    private func startSessionKeepAlive() {
        guard !isSignedOut else { return }
        let tokenProvider = AccessTokenProvider(tokenStore: tokenStore, refresher: oauthSession)
        let client = ChatCompletionClient()
        sessionKeepAlive = SessionKeepAlive(client: client)
        Task {
            let source = try? AuthDiscovery().resolve(preferredPath: preferredAuthPath.isEmpty ? nil : preferredAuthPath)
            if let source = source, let token = try? await tokenProvider.accessToken(for: source) {
                await sessionKeepAlive?.start(accessToken: token)
            }
        }
    }

    func setRefreshInterval(minutes: Int) {
        refreshIntervalSeconds = TimeInterval(minutes * 60)
        userDefaults.set(refreshIntervalSeconds, forKey: PreferenceKey.refreshIntervalSeconds)
        updateRefreshInterval()
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        launchAtLoginEnabled = enabled
        userDefaults.set(enabled, forKey: PreferenceKey.launchAtLoginEnabled)
        loginItemManager.setEnabled(enabled)
    }

    func rebuildServiceAndRefresh() {
        if isSignedOut {
            coordinator.stopAutoRefresh()
            coordinator.service = EmptyUsageService()
            coordinator.clearState()
            activeSourceLabel = ""
            return
        }

        do {
            let resolver = AuthResolver(discovery: AuthDiscovery(), tokenStore: tokenStore)
            let path = preferredAuthPath.isEmpty ? nil : preferredAuthPath
            let source = try resolver.resolve(preferredPath: path)
            activeSourceLabel = source.sourceLabel
            authMessage = source.connectionStatusLabel
            let tokenProvider = AccessTokenProvider(tokenStore: tokenStore, refresher: oauthSession)
            coordinator.service = AuthFallbackUsageService(
                initialSource: source,
                tokenStore: tokenStore,
                tokenProvider: tokenProvider,
                authResolver: resolver,
                onSourceChange: { [weak self] source in
                    self?.activeSourceLabel = source.sourceLabel
                    self?.authMessage = source.connectionStatusLabel
                }
            )
            coordinator.startAutoRefresh(interval: refreshIntervalSeconds)
            startSessionKeepAlive()
        } catch {
            authMessage = "Unable to resolve auth source: \(error)"
        }

        Task {
            await coordinator.refreshNow()
        }
    }

    func refreshNow() {
        guard !isSignedOut else { return }
        lastManualRefreshAt = Date()
        Task {
            await coordinator.refreshNow()
        }
    }

    func connectOAuth() {
        Task {
            do {
                let record = try await oauthSession.startOAuth()
                try tokenStore.saveTokenRecord(record, account: KeychainTokenStore.defaultAccount)
                isSignedOut = false
                rebuildServiceAndRefresh()
            } catch {
                authMessage = "OAuth failed: \(error)"
            }
        }
    }

    func saveManualToken(_ token: String) {
        do {
            try tokenStore.saveAccessToken(token, account: KeychainTokenStore.defaultAccount)
            isSignedOut = false
            rebuildServiceAndRefresh()
        } catch {
            authMessage = "Failed to save token: \(error)"
        }
    }

    func disconnectOAuth() {
        do {
            try tokenStore.removeAccessToken(account: KeychainTokenStore.defaultAccount)
        } catch {
            authMessage = "Failed to remove token: \(error)"
        }
    }

    func logout() {
        disconnectOAuth()
        isSignedOut = true
        authMessage = nil
        lastManualRefreshAt = nil
        rebuildServiceAndRefresh()
    }
}

private struct EmptyUsageService: UsageService {
    func fetchUsage() async throws -> UsageSnapshot {
        throw UsageClientError.unauthorized
    }
}

@MainActor
private final class AuthFallbackUsageService: UsageService {
    private var source: AuthSource
    private let tokenStore: TokenStore
    private let tokenProvider: AccessTokenProviding
    private let authResolver: AuthResolver
    private let onSourceChange: (AuthSource) -> Void

    init(
        initialSource: AuthSource,
        tokenStore: TokenStore,
        tokenProvider: AccessTokenProviding,
        authResolver: AuthResolver,
        onSourceChange: @escaping (AuthSource) -> Void
    ) {
        self.source = initialSource
        self.tokenStore = tokenStore
        self.tokenProvider = tokenProvider
        self.authResolver = authResolver
        self.onSourceChange = onSourceChange
    }

    func fetchUsage() async throws -> UsageSnapshot {
        do {
            return try await usageClient(for: source).fetchUsage()
        } catch UsageClientError.unauthorized {
            if let nextSource = authResolver.resolveNextSource(after: source) {
                source = nextSource
                onSourceChange(nextSource)
                return try await usageClient(for: nextSource).fetchUsage()
            }

            if let oauthAccessToken = try tokenStore.loadAccessToken(account: KeychainTokenStore.defaultAccount),
               !oauthAccessToken.isEmpty {
                let oauthSource = AuthSource.oauthKeychain(
                    service: KeychainTokenStore.serviceName,
                    account: KeychainTokenStore.defaultAccount
                )
                source = oauthSource
                onSourceChange(oauthSource)
                return try await usageClient(for: oauthSource).fetchUsage()
            }

            throw UsageClientError.unauthorized
        }
    }

    private func usageClient(for source: AuthSource) -> UsageClient {
        UsageClient(source: source, tokenProvider: tokenProvider)
    }
}
