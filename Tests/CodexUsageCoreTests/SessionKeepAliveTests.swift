import XCTest
@testable import CodexUsageCore

final class SessionKeepAliveTests: XCTestCase {
    func testStartsAndStops() async throws {
        let mockClient = MockChatCompletionClient()
        let keepAlive = SessionKeepAlive(client: mockClient)
        await keepAlive.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        await keepAlive.stop()
        XCTAssertTrue(mockClient.pingCount > 0)
    }
}
