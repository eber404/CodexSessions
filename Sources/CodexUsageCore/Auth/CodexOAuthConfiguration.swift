import Foundation

public enum CodexOAuthConfiguration {
    public static let clientID = "app_EMoamEEZ73f0CkXaXp7hrann"
    public static let authorizationEndpoint = URL(string: "https://auth.openai.com/oauth/authorize")!
    public static let tokenEndpoint = URL(string: "https://auth.openai.com/oauth/token")!
    public static let redirectURI = "http://localhost:1455/auth/callback"
    public static let authorizationScopes = ["openid", "profile", "email", "offline_access"]
    public static let refreshScope = "model.request offline_access"
}
