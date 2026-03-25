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

struct MockHTTPClient: HTTPClient {
    let responseData: Data
    let statusCode: Int

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (responseData, response)
    }
}
