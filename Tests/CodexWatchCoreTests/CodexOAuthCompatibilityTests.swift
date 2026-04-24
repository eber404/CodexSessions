import Foundation
import XCTest
@testable import CodexWatchCore

final class CodexOAuthCompatibilityTests: XCTestCase {
    func testCodexOAuthConfigurationMatchesReference() {
        XCTAssertEqual(CodexOAuthConfiguration.clientID, "app_EMoamEEZ73f0CkXaXp7hrann")
        XCTAssertEqual(CodexOAuthConfiguration.redirectURI, "http://localhost:1455/auth/callback")
        XCTAssertEqual(CodexOAuthConfiguration.authorizationScopes, ["openid", "profile", "email", "offline_access"])
    }

    func testDecoderReadsChatGPTAccountIDClaim() throws {
        let payload = "{\"https://api.openai.com/auth\":{\"chatgpt_account_id\":\"acct_123\"}}"
        let encodedPayload = Data(payload.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        let jwt = "header.\(encodedPayload).signature"

        XCTAssertEqual(OpenAITokenDecoder().decodeAccountID(from: jwt), "acct_123")
    }
}
