import XCTest
@testable import CodexUsageCore

final class SessionKeepAliveTests: XCTestCase {
    func testStartDoesNotPingWhenDisabled() async throws {
        let mockClient = MockChatCompletionClient()
        let keepAlive = SessionKeepAlive(client: mockClient)
        await keepAlive.configure(isEnabled: false, firstHour: 9)
        await keepAlive.start(accessToken: "test-token")
        try await Task.sleep(nanoseconds: 100_000_000)
        await keepAlive.stop()
        XCTAssertEqual(mockClient.pingCount, 0)
    }

    func testConfigureUpdatesSettings() async throws {
        let mockClient = MockChatCompletionClient()
        let keepAlive = SessionKeepAlive(client: mockClient)

        // Initially disabled - verify start returns early
        await keepAlive.start(accessToken: "test")
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(mockClient.pingCount, 0)

        // Configure enabled and restart - verify start() actually starts the task
        await keepAlive.configure(isEnabled: true, firstHour: 9)
        await keepAlive.start(accessToken: "test")
        try await Task.sleep(nanoseconds: 50_000_000)

        // Task should be running (even if waiting for firstHour)
        let taskIsRunning = await keepAlive.isRunning
        XCTAssertTrue(taskIsRunning)
    }

    func testCancellationStopsTask() async throws {
        let mockClient = MockChatCompletionClient()
        let keepAlive = SessionKeepAlive(client: mockClient)
        await keepAlive.configure(isEnabled: true, firstHour: 9)
        await keepAlive.start(accessToken: "test-token")
        try await Task.sleep(nanoseconds: 50_000_000)
        await keepAlive.stop()
        let countAfterStop = mockClient.pingCount
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(mockClient.pingCount, countAfterStop)
    }
}
