import Foundation
import XCTest
@testable import CodexWatchCore

@MainActor
final class RefreshCoordinatorTests: XCTestCase {
    func testFailedRefreshKeepsLastSnapshotAndMarksStateStale() async throws {
        let now = Date(timeIntervalSince1970: 1000)
        let snapshot = UsageSnapshot(
            accountEmail: "user@example.com",
            sourceLabel: "local",
            windows: [
                UsageWindow(kind: .shortWindow, label: "Daily", used: 10, limit: 100, resetAt: now.addingTimeInterval(3600)),
            ],
            fetchedAt: now
        )

        let succeeding = StubUsageService(result: .success(snapshot))
        let failing = StubUsageService(result: .failure(UsageClientError.unauthorized))

        let coordinator = RefreshCoordinator(service: succeeding)
        await coordinator.refreshNow()
        XCTAssertEqual(coordinator.state.snapshot?.accountEmail, "user@example.com")
        XCTAssertFalse(coordinator.state.isStale)

        coordinator.service = failing
        await coordinator.refreshNow()

        XCTAssertEqual(coordinator.state.snapshot?.accountEmail, "user@example.com")
        XCTAssertTrue(coordinator.state.isStale)
        XCTAssertNotNil(coordinator.state.lastError)
    }

    func testRefreshNowUpdatesLastRefreshAtOnEveryManualRefresh() async throws {
        let now = Date(timeIntervalSince1970: 2000)
        let snapshot = UsageSnapshot(
            accountEmail: "user@example.com",
            sourceLabel: "local",
            windows: [
                UsageWindow(kind: .shortWindow, label: "Daily", used: 10, limit: 100, resetAt: now.addingTimeInterval(3600)),
            ],
            fetchedAt: now
        )

        let coordinator = RefreshCoordinator(service: StubUsageService(result: .success(snapshot)))
        XCTAssertNil(coordinator.state.lastRefreshAt)

        await coordinator.refreshNow()
        let firstRefresh = try XCTUnwrap(coordinator.state.lastRefreshAt)

        try? await Task.sleep(nanoseconds: 20_000_000)
        await coordinator.refreshNow()
        let secondRefresh = try XCTUnwrap(coordinator.state.lastRefreshAt)

        XCTAssertGreaterThan(secondRefresh, firstRefresh)
    }

    func testClearStateRemovesSnapshotAndRefreshMetadata() async throws {
        let now = Date(timeIntervalSince1970: 3000)
        let snapshot = UsageSnapshot(
            accountEmail: "user@example.com",
            sourceLabel: "local",
            windows: [
                UsageWindow(kind: .shortWindow, label: "Daily", used: 10, limit: 100, resetAt: now.addingTimeInterval(3600)),
            ],
            fetchedAt: now
        )

        let coordinator = RefreshCoordinator(service: StubUsageService(result: .success(snapshot)))
        await coordinator.refreshNow()

        XCTAssertNotNil(coordinator.state.snapshot)
        XCTAssertNotNil(coordinator.state.lastRefreshAt)

        coordinator.clearState()

        XCTAssertNil(coordinator.state.snapshot)
        XCTAssertNil(coordinator.state.lastRefreshAt)
        XCTAssertNil(coordinator.state.lastError)
    }

    func testAutoRefreshRunsInBackground() async throws {
        let now = Date(timeIntervalSince1970: 4000)
        let snapshot = UsageSnapshot(
            accountEmail: "user@example.com",
            sourceLabel: "local",
            windows: [
                UsageWindow(kind: .shortWindow, label: "Daily", used: 10, limit: 100, resetAt: now.addingTimeInterval(3600)),
            ],
            fetchedAt: now
        )

        let service = CountingUsageService(snapshot: snapshot)
        let coordinator = RefreshCoordinator(service: service)
        coordinator.startAutoRefresh(interval: 0.05)

        defer { coordinator.stopAutoRefresh() }

        try? await Task.sleep(nanoseconds: 130_000_000)

        XCTAssertNotNil(coordinator.state.lastRefreshAt)
        XCTAssertNotNil(coordinator.state.snapshot)
        XCTAssertGreaterThanOrEqual(service.fetchCount, 2)
    }
}

private struct StubUsageService: UsageService {
    let result: Result<UsageSnapshot, Error>

    func fetchUsage() async throws -> UsageSnapshot {
        try result.get()
    }
}

@MainActor
private final class CountingUsageService: UsageService {
    private(set) var fetchCount = 0
    private let snapshot: UsageSnapshot

    init(snapshot: UsageSnapshot) {
        self.snapshot = snapshot
    }

    func fetchUsage() async throws -> UsageSnapshot {
        fetchCount += 1
        return snapshot
    }
}
