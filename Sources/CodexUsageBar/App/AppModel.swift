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
    @Published var lastManualRefreshAt: Date?
    @Published var isSignedOut: Bool = false

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
    }

    func updateRefreshInterval() {
        if !isSignedOut {
            coordinator.startAutoRefresh(interval: refreshIntervalSeconds)
        }
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
            coordinator.service = UsageClient(
                source: source,
                tokenProvider: AccessTokenProvider(tokenStore: tokenStore, refresher: oauthSession)
            )
            coordinator.startAutoRefresh(interval: refreshIntervalSeconds)
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
            isSignedOut = false
            authMessage = "Token saved"
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
