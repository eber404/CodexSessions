import Foundation
@testable import CodexUsageCore

struct FakeFileManager: FileManaging {
    let existingPaths: Set<String>

    init(existingPaths: [String]) {
        self.existingPaths = Set(existingPaths)
    }

    func fileExists(atPath path: String) -> Bool {
        existingPaths.contains(path)
    }
}

final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    let responseData: Data
    let statusCode: Int
    var onRequest: ((URLRequest) -> Void)?

    init(responseData: Data, statusCode: Int) {
        self.responseData = responseData
        self.statusCode = statusCode
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        onRequest?(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (responseData, response)
    }
}

final class MockChatCompletionClient: ChatCompletionClientProtocol, @unchecked Sendable {
    public private(set) var pingCount = 0

    public init() {}

    public func sendPing(accessToken: String) async throws {
        pingCount += 1
    }
}
