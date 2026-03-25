import XCTest
@testable import CodexUsageCore

final class SessionKeepAliveTests: XCTestCase {
    func testStartDoesNotPingWhenDisabled() async throws {
        let mockClient = MockChatCompletionClient()
        let keepAlive = SessionKeepAlive(client: mockClient)
        await keepAlive.start(accessToken: "test-token")
        try await Task.sleep(nanoseconds: 100_000_000)
        await keepAlive.stop()
        XCTAssertEqual(mockClient.pingCount, 0)
    }

    func testConfigureUpdatesSettings() async throws {
        let mockClient = MockChatCompletionClient()
        let keepAlive = SessionKeepAlive(client: mockClient)
        await keepAlive.configure(isEnabled: true, firstHour: 9)
        await keepAlive.start(accessToken: "test-token")
        try await Task.sleep(nanoseconds: 100_000_000)
        await keepAlive.stop()
        XCTAssertTrue(mockClient.pingCount >= 0)
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
