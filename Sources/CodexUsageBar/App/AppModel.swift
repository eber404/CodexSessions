import CodexUsageCore
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var preferredAuthPath: String = ""
    @Published var refreshIntervalSeconds: TimeInterval = 300
    @Published var showUsedInsteadOfRemaining: Bool = false
    @Published var activeSourceLabel: String = "Detecting..."
    @Published var authMessage: String?

    let tokenStore: KeychainTokenStore
    let coordinator: RefreshCoordinator

    private let oauthSession: OpenAIOAuthSession

    init(tokenStore: KeychainTokenStore = KeychainTokenStore(), oauthSession: OpenAIOAuthSession = OpenAIOAuthSession()) {
        self.tokenStore = tokenStore
        self.oauthSession = oauthSession
        self.coordinator = RefreshCoordinator(service: EmptyUsageService())
    }

    func start() {
        rebuildServiceAndRefresh()
        coordinator.startAutoRefresh(interval: refreshIntervalSeconds)
    }

    func updateRefreshInterval() {
        coordinator.startAutoRefresh(interval: refreshIntervalSeconds)
    }

    func rebuildServiceAndRefresh() {
        do {
            let resolver = AuthResolver(discovery: AuthDiscovery(), tokenStore: tokenStore)
            let path = preferredAuthPath.isEmpty ? nil : preferredAuthPath
            let source = try resolver.resolve(preferredPath: path)
            activeSourceLabel = source.sourceLabel
            coordinator.service = UsageClient(
                source: source,
                tokenProvider: AccessTokenProvider(tokenStore: tokenStore, refresher: oauthSession)
            )
        } catch {
            authMessage = "Unable to resolve auth source: \(error)"
        }

        Task {
            await coordinator.refreshNow()
        }
    }

    func refreshNow() {
        Task {
            await coordinator.refreshNow()
        }
    }

    func connectOAuth() {
        Task {
            do {
                let record = try await oauthSession.startOAuth()
                try tokenStore.saveTokenRecord(record, account: KeychainTokenStore.defaultAccount)
                authMessage = "OAuth connected"
                rebuildServiceAndRefresh()
            } catch {
                authMessage = "OAuth failed: \(error)"
            }
        }
    }

    func saveManualToken(_ token: String) {
        do {
            try tokenStore.saveAccessToken(token, account: KeychainTokenStore.defaultAccount)
            authMessage = "Token saved"
            rebuildServiceAndRefresh()
        } catch {
            authMessage = "Failed to save token: \(error)"
        }
    }

    func disconnectOAuth() {
        do {
            try tokenStore.removeAccessToken(account: KeychainTokenStore.defaultAccount)
            authMessage = "OAuth token removed"
            rebuildServiceAndRefresh()
        } catch {
            authMessage = "Failed to remove token: \(error)"
        }
    }
}

private struct EmptyUsageService: UsageService {
    func fetchUsage() async throws -> UsageSnapshot {
        throw UsageClientError.unauthorized
    }
}
