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

    func testSendPingForbiddenReturnsUnauthorized() async throws {
        let mockHTTP = MockHTTPClient(responseData: Data(), statusCode: 403)
        let client = ChatCompletionClient(httpClient: mockHTTP)
        do {
            try await client.sendPing(accessToken: "forbidden-token")
            XCTFail("Expected error")
        } catch ChatCompletionError.unauthorized {
            // expected
        }
    }

    func testSendPingServerError() async throws {
        let mockHTTP = MockHTTPClient(responseData: Data(), statusCode: 500)
        let client = ChatCompletionClient(httpClient: mockHTTP)
        do {
            try await client.sendPing(accessToken: "test-token")
            XCTFail("Expected error")
        } catch ChatCompletionError.serverError {
            // expected
        }
    }
}
