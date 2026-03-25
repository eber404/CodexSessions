import Combine
import Foundation

public struct RefreshState: Sendable {
    public var snapshot: UsageSnapshot?
    public var lastRefreshAt: Date?
    public var isLoading: Bool
    public var isStale: Bool
    public var lastError: String?

    public init(snapshot: UsageSnapshot? = nil, lastRefreshAt: Date? = nil, isLoading: Bool = false, isStale: Bool = false, lastError: String? = nil) {
        self.snapshot = snapshot
        self.lastRefreshAt = lastRefreshAt
        self.isLoading = isLoading
        self.isStale = isStale
        self.lastError = lastError
    }
}

@MainActor
public final class RefreshCoordinator: ObservableObject {
    @Published public private(set) var state: RefreshState
    public var service: UsageService

    private var refreshTask: Task<Void, Never>?

    public init(service: UsageService, initialState: RefreshState = RefreshState()) {
        self.service = service
        self.state = initialState
    }

    deinit {
        refreshTask?.cancel()
    }

    public func startAutoRefresh(interval: TimeInterval) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refreshNow()
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    public func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    public func refreshNow() async {
        state.lastRefreshAt = Date()
        state.isLoading = true
        do {
            let snapshot = try await service.fetchUsage()
            state.snapshot = snapshot
            state.lastError = nil
            state.isStale = false
        } catch {
            state.lastError = String(describing: error)
            state.isStale = state.snapshot != nil
        }
        state.isLoading = false
    }
}
