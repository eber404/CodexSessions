import CommonCrypto
import Foundation
import AppKit
import Network
import CodexUsageCore

enum OpenAIOAuthError: Error {
    case invalidState
    case callbackMissing
    case codeExchangeFailed
    case invalidRedirectURI
    case cannotOpenBrowser
    case callbackTimedOut
}

@MainActor
final class OpenAIOAuthSession: NSObject, OAuthTokenRefreshing {
    private let tokenDecoder = OpenAITokenDecoder()

    func startOAuth() async throws -> OAuthTokenRecord {
        let redirectURI = CodexOAuthConfiguration.redirectURI
        let state = UUID().uuidString
        let verifier = PKCE.generateVerifier()
        let challenge = PKCE.challenge(for: verifier)

        var components = URLComponents(url: CodexOAuthConfiguration.authorizationEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: CodexOAuthConfiguration.clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: CodexOAuthConfiguration.authorizationScopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
        ]

        guard let url = components.url else {
            throw OpenAIOAuthError.callbackMissing
        }

        let callbackURL = try await runDefaultBrowserLoopbackSession(startURL: url, redirectURI: redirectURI)
        let queryItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems

        guard let authCode = queryItems?.first(where: { $0.name == "code" })?.value else {
            throw OpenAIOAuthError.callbackMissing
        }
        guard queryItems?.first(where: { $0.name == "state" })?.value == state else {
            throw OpenAIOAuthError.invalidState
        }

        return try await exchangeCodeForToken(
            code: authCode,
            verifier: verifier,
            redirectURI: redirectURI
        )
    }

    private func runDefaultBrowserLoopbackSession(startURL: URL, redirectURI: String) async throws -> URL {
        guard let redirectURL = URL(string: redirectURI),
              let redirectComponents = URLComponents(url: redirectURL, resolvingAgainstBaseURL: false),
              redirectComponents.scheme == "http",
              let host = redirectComponents.host,
              let port = redirectComponents.port
        else {
            throw OpenAIOAuthError.invalidRedirectURI
        }

        let path = redirectComponents.path.isEmpty ? "/" : redirectComponents.path
        let listener = LocalhostOAuthCallbackListener(host: host, port: UInt16(port), path: path)
        let callbackTask = Task {
            try await listener.waitForCallback()
        }

        guard NSWorkspace.shared.open(startURL) else {
            callbackTask.cancel()
            throw OpenAIOAuthError.cannotOpenBrowser
        }

        do {
            return try await callbackTask.value
        } catch is CancellationError {
            throw OpenAIOAuthError.callbackMissing
        } catch {
            throw error
        }
    }

    private func exchangeCodeForToken(code: String, verifier: String, redirectURI: String) async throws -> OAuthTokenRecord {
        var request = URLRequest(url: CodexOAuthConfiguration.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "authorization_code",
            "client_id": CodexOAuthConfiguration.clientID,
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": verifier,
        ]
        request.httpBody = body
            .map { key, value in "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OpenAIOAuthError.codeExchangeFailed
        }

        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any],
              let accessToken = dictionary["access_token"] as? String,
              !accessToken.isEmpty
        else {
            throw OpenAIOAuthError.codeExchangeFailed
        }

        let refreshToken = dictionary["refresh_token"] as? String
        let expiresIn = dictionary["expires_in"] as? Int
        let expiresAt = expiresIn.map { Int(Date().timeIntervalSince1970) + $0 }
        let accountID = tokenDecoder.decodeAccountID(from: accessToken)

        return OAuthTokenRecord(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            accountId: accountID
        )
    }

    func refreshAccessToken(refreshToken: String) async throws -> OAuthTokenRecord {
        var request = URLRequest(url: CodexOAuthConfiguration.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "client_id": CodexOAuthConfiguration.clientID,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "scope": CodexOAuthConfiguration.refreshScope,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OpenAIOAuthError.codeExchangeFailed
        }

        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any],
              let accessToken = dictionary["access_token"] as? String,
              !accessToken.isEmpty
        else {
            throw OpenAIOAuthError.codeExchangeFailed
        }

        let newRefresh = dictionary["refresh_token"] as? String
        let expiresIn = dictionary["expires_in"] as? Int
        let expiresAt = expiresIn.map { Int(Date().timeIntervalSince1970) + $0 }
        let accountID = tokenDecoder.decodeAccountID(from: accessToken)

        return OAuthTokenRecord(
            accessToken: accessToken,
            refreshToken: newRefresh ?? refreshToken,
            expiresAt: expiresAt,
            accountId: accountID
        )
    }
}

private final class LocalhostOAuthCallbackListener: @unchecked Sendable {
    private let expectedHost: String
    private let expectedPort: UInt16
    private let expectedPath: String

    init(host: String, port: UInt16, path: String) {
        self.expectedHost = host
        self.expectedPort = port
        self.expectedPath = path
    }

    private final class CallbackCompletionState: @unchecked Sendable {
        private let queue: DispatchQueue
        private let continuation: CheckedContinuation<URL, Error>
        private var listener: NWListener?
        private var isCompleted = false

        init(queue: DispatchQueue, continuation: CheckedContinuation<URL, Error>) {
            self.queue = queue
            self.continuation = continuation
        }

        func setListener(_ listener: NWListener) {
            queue.async {
                self.listener = listener
            }
        }

        func finish(_ result: Result<URL, Error>) {
            queue.async {
                guard !self.isCompleted else { return }
                self.isCompleted = true
                self.listener?.cancel()
                self.continuation.resume(with: result)
            }
        }
    }

    func waitForCallback(timeout: TimeInterval = 180) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let queue = DispatchQueue(label: "OpenAIOAuthSession.loopback")
            let completion = CallbackCompletionState(queue: queue, continuation: continuation)

            do {
                guard let port = NWEndpoint.Port(rawValue: expectedPort) else {
                    completion.finish(.failure(OpenAIOAuthError.invalidRedirectURI))
                    return
                }

                let newListener = try NWListener(using: .tcp, on: port)
                completion.setListener(newListener)

                newListener.stateUpdateHandler = { state in
                    if case .failed(let error) = state {
                        completion.finish(.failure(error))
                    }
                }

                newListener.newConnectionHandler = { connection in
                    connection.start(queue: queue)
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 16_384) { data, _, _, receiveError in
                        if let receiveError {
                            connection.cancel()
                            completion.finish(.failure(receiveError))
                            return
                        }

                        guard let data, let requestTarget = self.requestTarget(from: data) else {
                            self.respond(to: connection, status: "400 Bad Request", body: "Invalid callback request")
                            return
                        }

                        guard let callbackURL = self.callbackURL(from: requestTarget) else {
                            self.respond(to: connection, status: "404 Not Found", body: "Unknown callback path")
                            return
                        }

                        self.respond(
                            to: connection,
                            status: "200 OK",
                            body: "<html><body><h3>Sign-in complete.</h3><p>You can close this tab and return to CodexSessions.</p></body></html>"
                        )
                        completion.finish(.success(callbackURL))
                    }
                }

                newListener.start(queue: queue)

                queue.asyncAfter(deadline: .now() + timeout) {
                    completion.finish(.failure(OpenAIOAuthError.callbackTimedOut))
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func requestTarget(from data: Data) -> String? {
        guard let request = String(data: data, encoding: .utf8),
              let firstLine = request.components(separatedBy: "\r\n").first
        else {
            return nil
        }

        let components = firstLine.split(separator: " ")
        guard components.count >= 2 else { return nil }
        return String(components[1])
    }

    private func callbackURL(from requestTarget: String) -> URL? {
        let url: URL?
        if let absolute = URL(string: requestTarget), absolute.scheme != nil {
            url = absolute
        } else {
            url = URL(string: "http://\(expectedHost):\(expectedPort)\(requestTarget)")
        }

        guard let url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.host?.caseInsensitiveCompare(expectedHost) == .orderedSame,
              components.port == Int(expectedPort),
              components.path == expectedPath
        else {
            return nil
        }

        return url
    }

    private func respond(to connection: NWConnection, status: String, body: String) {
        let bodyData = Data(body.utf8)
        let header = "HTTP/1.1 \(status)\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(bodyData.count)\r\nConnection: close\r\n\r\n"
        var response = Data(header.utf8)
        response.append(bodyData)

        connection.send(content: response, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

private enum PKCE {
    static func generateVerifier() -> String {
        UUID().uuidString + UUID().uuidString
    }

    static func challenge(for verifier: String) -> String {
        let data = Data(verifier.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        let hashData = Data(digest)
        return hashData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
