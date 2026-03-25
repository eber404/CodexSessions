import Foundation

public enum ChatCompletionError: Error {
    case unauthorized
    case serverError
    case invalidResponse
}

public struct ChatCompletionClient {
    private let tokenProvider: AccessTokenProviding
    private let httpClient: HTTPClient
    private let baseURL = URL(string: "https://api.openai.com")!

    public init(
        tokenProvider: AccessTokenProviding = AccessTokenProvider(),
        httpClient: HTTPClient = URLSessionHTTPClient()
    ) {
        self.tokenProvider = tokenProvider
        self.httpClient = httpClient
    }

    public func sendPing(accessToken: String) async throws {
        let request = ChatCompletionRequest(
            messages: [ChatCompletionRequest.Message(role: "user", content: "oi")]
        )
        let body = try JSONEncoder().encode(request)

        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("v1/chat/completions"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = body

        let (_, response) = try await httpClient.data(for: urlRequest)

        switch response.statusCode {
        case 200:
            return
        case 401, 403:
            throw ChatCompletionError.unauthorized
        default:
            throw ChatCompletionError.serverError
        }
    }
}
