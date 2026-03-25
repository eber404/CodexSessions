import XCTest
@testable import CodexUsageCore

final class ChatCompletionClientTests: XCTestCase {
    func testSendPingSucceeds() async throws {
        let mockHTTP = MockHTTPClient(responseData: Data(), statusCode: 200)
        let client = ChatCompletionClient(httpClient: mockHTTP)
        try await client.sendPing(accessToken: "test-token")
    }

    func testSendPingUnauthorized() async throws {
        let mockHTTP = MockHTTPClient(responseData: Data(), statusCode: 401)
        let client = ChatCompletionClient(httpClient: mockHTTP)
        do {
            try await client.sendPing(accessToken: "bad-token")
            XCTFail("Expected error")
        } catch ChatCompletionError.unauthorized {
            // expected
        }
    }
}
