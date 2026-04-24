import XCTest
@testable import CodexUsageCore

final class KeepAliveClientTests: XCTestCase {
    func testSendPingTargetsCodexSessionEndpoint() async throws {
        var capturedRequest: URLRequest?
        let mockHTTP = MockHTTPClient(responseData: Data(), statusCode: 200)
        mockHTTP.onRequest = { capturedRequest = $0 }
        let client = KeepAliveClient(httpClient: mockHTTP)

        try await client.sendPing(accessToken: "test-token")

        XCTAssertEqual(capturedRequest?.url?.absoluteString, "https://chatgpt.com/backend-api/wham/usage")
        XCTAssertEqual(capturedRequest?.httpMethod, "GET")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
    }

    func testSendPingIncludesStatusCodeAndBodySnippetForServerError() async throws {
        let body = Data("backend exploded badly".utf8)
        let mockHTTP = MockHTTPClient(responseData: body, statusCode: 500)
        let client = KeepAliveClient(httpClient: mockHTTP)

        do {
            try await client.sendPing(accessToken: "test-token")
            XCTFail("Expected error")
        } catch let KeepAliveError.serverError(statusCode, bodySnippet) {
            XCTAssertEqual(statusCode, 500)
            XCTAssertEqual(bodySnippet, "backend exploded badly")
        }
    }

    func testSendPingIncludesStatusCodeAndBodySnippetForUnexpectedResponse() async throws {
        let body = Data("bad req".utf8)
        let mockHTTP = MockHTTPClient(responseData: body, statusCode: 400)
        let client = KeepAliveClient(httpClient: mockHTTP)

        do {
            try await client.sendPing(accessToken: "test-token")
            XCTFail("Expected error")
        } catch let KeepAliveError.invalidResponse(statusCode, bodySnippet) {
            XCTAssertEqual(statusCode, 400)
            XCTAssertEqual(bodySnippet, "bad req")
        }
    }
}
