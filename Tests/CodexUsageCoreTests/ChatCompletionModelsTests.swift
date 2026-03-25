import XCTest
@testable import CodexUsageCore

final class ChatCompletionModelsTests: XCTestCase {
    func testRequestEncoding() {
        let request = ChatCompletionRequest(
            messages: [ChatCompletionRequest.Message(role: "user", content: "oi")]
        )
        let data = try! JSONEncoder().encode(request)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains("gpt-4o"))
        XCTAssertTrue(json.contains("oi"))
    }

    func testResponseDecoding() {
        let json = #"{"id":"chat-123","choices":[{"message":{"role":"assistant","content":"OK"},"finish_reason":"stop"}]}"#
        let data = json.data(using: .utf8)!
        let response = try! JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        XCTAssertEqual(response.id, "chat-123")
    }
}
