import XCTest
@testable import CodexUsageCore

final class UsageRequestBuilderTests: XCTestCase {
    func testBuildsUsageEndpointRequest() throws {
        let request = try UsageRequestBuilder().makeRequest(accessToken: "token")

        XCTAssertEqual(request.url?.absoluteString, "https://chatgpt.com/backend-api/wham/usage")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }
}
