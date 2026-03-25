import XCTest
@testable import CodexUsageCore

final class ChatCompletionClientTests: XCTestCase {
    func testSendPingSucceeds() async throws {
        var capturedRequest: URLRequest?
        let mockHTTP = MockHTTPClient(responseData: Data(), statusCode: 200)
        mockHTTP.onRequest = { capturedRequest = $0 }
        let client = ChatCompletionClient(httpClient: mockHTTP)
        try await client.sendPing(accessToken: "test-token")

        guard let request = capturedRequest else {
            XCTFail("No request was made")
            return
        }

        XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/chat/completions")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.timeoutInterval, 30)

        XCTAssertNotNil(request.httpBody)
        let bodyDict = try JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Any]
        XCTAssertEqual(bodyDict?["model"] as? String, "gpt-4o")
        let messages = bodyDict?["messages"] as? [[String: Any]]
        XCTAssertEqual(messages?.count, 1)
        XCTAssertEqual(messages?[0]["role"] as? String, "user")
        XCTAssertEqual(messages?[0]["content"] as? String, "oi")
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
