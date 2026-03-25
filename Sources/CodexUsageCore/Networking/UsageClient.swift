import Foundation

public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UsageClientError.invalidResponse
        }
        return (data, httpResponse)
    }
}

public enum UsageClientError: Error {
    case unauthorized
    case rateLimited
    case serverError
    case invalidResponse
}

@MainActor
public protocol UsageService {
    func fetchUsage() async throws -> UsageSnapshot
}

public struct UsageClient: UsageService {
    private let source: AuthSource
    private let tokenProvider: AccessTokenProviding
    private let requestBuilder: UsageRequestBuilder
    private let parser: UsageResponseParser
    private let httpClient: HTTPClient

    public init(
        source: AuthSource,
        tokenProvider: AccessTokenProviding = AccessTokenProvider(),
        requestBuilder: UsageRequestBuilder = UsageRequestBuilder(),
        parser: UsageResponseParser = UsageResponseParser(),
        httpClient: HTTPClient = URLSessionHTTPClient()
    ) {
        self.source = source
        self.tokenProvider = tokenProvider
        self.requestBuilder = requestBuilder
        self.parser = parser
        self.httpClient = httpClient
    }

    public func fetchUsage() async throws -> UsageSnapshot {
        do {
            let token = try await tokenProvider.accessToken(for: source)
            let request = try requestBuilder.makeRequest(accessToken: token)
            let (data, response) = try await httpClient.data(for: request)

            switch response.statusCode {
            case 200:
                return try parser.parse(data: data, sourceLabel: source.sourceLabel)
            case 401, 403:
                throw UsageClientError.unauthorized
            case 429:
                throw UsageClientError.rateLimited
            case 500 ... 599:
                throw UsageClientError.serverError
            default:
                throw UsageClientError.invalidResponse
            }
        } catch AccessTokenProviderError.expiredAccessToken {
            throw UsageClientError.unauthorized
        }
    }
}
