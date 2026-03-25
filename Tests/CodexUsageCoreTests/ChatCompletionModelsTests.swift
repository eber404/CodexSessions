import XCTest
@testable import CodexUsageCore

final class ChatCompletionModelsTests: XCTestCase {
    func testRequestEncoding() {
        let request = ChatCompletionRequest(
            messages: [ChatCompletionRequest.Message(role: "user", content: "oi")]
        )
        guard let data = try? JSONEncoder().encode(request),
              let json = String(data: data, encoding: .utf8) else {
            XCTFail("Failed to encode request")
            return
        }
        XCTAssertTrue(json.contains("gpt-4o"))
        XCTAssertTrue(json.contains("oi"))
    }

    func testResponseDecoding() {
        let json = #"{"id":"chat-123","choices":[{"message":{"role":"assistant","content":"OK"},"finish_reason":"stop"}]}"#
        guard let data = json.data(using: .utf8) else {
            XCTFail("Failed to create data from json")
            return
        }
        guard let response = try? JSONDecoder().decode(ChatCompletionResponse.self, from: data) else {
            XCTFail("Failed to decode response")
            return
        }
        XCTAssertEqual(response.id, "chat-123")

        guard let choices = response.choices, let firstChoice = choices.first else {
            XCTFail("Missing or empty choices array")
            return
        }
        XCTAssertEqual(firstChoice.finishReason, "stop")
        XCTAssertEqual(firstChoice.message?.content, "OK")
        XCTAssertEqual(firstChoice.message?.role, "assistant")
    }

    func testChoiceFinishReasonEncoding() {
        let choice = ChatCompletionResponse.Choice(
            message: ChatCompletionResponse.Message(role: "assistant", content: "Hi"),
            finishReason: "stop"
        )
        guard let data = try? JSONEncoder().encode(choice),
              let json = String(data: data, encoding: .utf8) else {
            XCTFail("Failed to encode choice")
            return
        }
        XCTAssertTrue(json.contains("finish_reason"))
        XCTAssertTrue(json.contains("stop"))

        guard let decoded = try? JSONDecoder().decode(ChatCompletionResponse.Choice.self, from: data) else {
            XCTFail("Failed to decode choice")
            return
        }
        XCTAssertEqual(decoded.finishReason, "stop")
    }
}