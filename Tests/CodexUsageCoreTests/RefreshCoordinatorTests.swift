import Foundation
import XCTest
@testable import CodexUsageCore

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
}

private struct StubUsageService: UsageService {
    let result: Result<UsageSnapshot, Error>

    func fetchUsage() async throws -> UsageSnapshot {
        try result.get()
    }
}
