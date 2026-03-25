import AuthenticationServices
import CommonCrypto
import Foundation
import AppKit
import CodexUsageCore

enum OpenAIOAuthError: Error {
    case invalidState
    case callbackMissing
    case codeExchangeFailed
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

        let callbackURL = try await runWebSession(startURL: url, callbackScheme: "http")
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

    private func runWebSession(startURL: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: startURL, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: OpenAIOAuthError.callbackMissing)
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = AuthPresentationContextProvider.shared
            _ = session.start()
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

private final class AuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = AuthPresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApplication.shared.windows.first ?? ASPresentationAnchor()
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
