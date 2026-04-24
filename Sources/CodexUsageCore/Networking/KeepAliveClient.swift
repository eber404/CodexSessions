import Foundation

public enum KeepAliveError: Error, Equatable {
    case unauthorized
    case rateLimited
    case serverError(statusCode: Int, bodySnippet: String?)
    case invalidResponse(statusCode: Int, bodySnippet: String?)
}

public protocol KeepAliveClientProtocol: Sendable {
    func sendPing(accessToken: String) async throws
}

public struct KeepAliveClient: KeepAliveClientProtocol {
    private let httpClient: HTTPClient
    private let requestBuilder: UsageRequestBuilder

    public init(
        httpClient: HTTPClient = URLSessionHTTPClient(),
        requestBuilder: UsageRequestBuilder = UsageRequestBuilder()
    ) {
        self.httpClient = httpClient
        self.requestBuilder = requestBuilder
    }

    public func sendPing(accessToken: String) async throws {
        let request = try requestBuilder.makeRequest(accessToken: accessToken)
        let (data, response) = try await httpClient.data(for: request)
        let bodySnippet = String(data: data.prefix(200), encoding: .utf8)

        switch response.statusCode {
        case 200:
            return
        case 401, 403:
            throw KeepAliveError.unauthorized
        case 429:
            throw KeepAliveError.rateLimited
        case 500 ... 599:
            throw KeepAliveError.serverError(statusCode: response.statusCode, bodySnippet: bodySnippet)
        default:
            throw KeepAliveError.invalidResponse(statusCode: response.statusCode, bodySnippet: bodySnippet)
        }
    }
}
