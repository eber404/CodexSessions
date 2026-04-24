import XCTest
@testable import CodexWatchCore

final class SessionKeepAliveTests: XCTestCase {
    func testStartDoesNotPingWhenDisabled() async throws {
        let mockClient = MockKeepAliveClient()
        let tokenProvider = MockKeepAliveTokenProvider(tokens: ["test-token"])
        let keepAlive = SessionKeepAlive(client: mockClient, tokenProvider: tokenProvider)
        await keepAlive.configure(isEnabled: false, firstHour: 9)
        await keepAlive.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        await keepAlive.stop()
        let pingCount = await mockClient.pingCount()
        XCTAssertEqual(pingCount, 0)
    }

    func testConfigureUpdatesSettings() async throws {
        let mockClient = MockKeepAliveClient()
        let tokenProvider = MockKeepAliveTokenProvider(tokens: ["test"])
        let keepAlive = SessionKeepAlive(client: mockClient, tokenProvider: tokenProvider)

        // Initially disabled - verify start returns early
        await keepAlive.start()
        try await Task.sleep(nanoseconds: 50_000_000)
        let initialPingCount = await mockClient.pingCount()
        XCTAssertEqual(initialPingCount, 0)

        // Configure enabled and restart - verify start() actually starts the task
        await keepAlive.configure(isEnabled: true, firstHour: 9)
        await keepAlive.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        // Task should be running (even if waiting for firstHour)
        let taskIsRunning = await keepAlive.isRunning
        XCTAssertTrue(taskIsRunning)
    }

    func testCancellationStopsTask() async throws {
        let mockClient = MockKeepAliveClient()
        let tokenProvider = MockKeepAliveTokenProvider(tokens: ["test-token"])
        let keepAlive = SessionKeepAlive(client: mockClient, tokenProvider: tokenProvider)
        await keepAlive.configure(isEnabled: true, firstHour: 9)
        await keepAlive.start()
        try await Task.sleep(nanoseconds: 50_000_000)
        await keepAlive.stop()
        let countAfterStop = await mockClient.pingCount()
        try await Task.sleep(nanoseconds: 100_000_000)
        let finalPingCount = await mockClient.pingCount()
        XCTAssertEqual(finalPingCount, countAfterStop)
    }

    func testStartResolvesFreshTokenForEachPing() async throws {
        let tokenProvider = MockKeepAliveTokenProvider(tokens: ["token-1", "token-2"])
        let mockClient = MockKeepAliveClient()
        let keepAlive = SessionKeepAlive(client: mockClient, tokenProvider: tokenProvider)

        await keepAlive.pingForTesting()
        await keepAlive.pingForTesting()

        let requestCount = await tokenProvider.requestCount()
        let receivedTokens = await mockClient.receivedTokens()
        XCTAssertEqual(requestCount, 2)
        XCTAssertEqual(receivedTokens, ["token-1", "token-2"])
    }
}

private actor MockKeepAliveTokenProvider: KeepAliveTokenProviding {
    private var tokens: [String]
    private var count = 0

    init(tokens: [String]) {
        self.tokens = tokens
    }

    func accessToken() async throws -> String {
        count += 1
        return tokens.removeFirst()
    }

    func requestCount() -> Int {
        count
    }
}
