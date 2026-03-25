import Foundation

public struct ChatCompletionRequest: Codable {
    public let model: String
    public let messages: [Message]

    public struct Message: Codable {
        public let role: String
        public let content: String

        enum CodingKeys: String, CodingKey {
            case role
            case content
        }
    }

    public init(model: String = "gpt-4o", messages: [Message]) {
        self.model = model
        self.messages = messages
    }
}

public struct ChatCompletionResponse: Codable {
    public let id: String?
    public let choices: [Choice]?

    public struct Choice: Codable {
        public let message: Message?
        public let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }

    public struct Message: Codable {
        public let role: String?
        public let content: String?
    }
}
