import Foundation

public enum UsageRequestError: Error {
    case invalidURL
}

public struct UsageRequestBuilder: Sendable {
    public init() {}

    public func makeRequest(accessToken: String) throws -> URLRequest {
        guard let url = URL(string: "https://chatgpt.com/backend-api/wham/usage") else {
            throw UsageRequestError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.timeoutInterval = 30
        return request
    }
}
