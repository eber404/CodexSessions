import Foundation
import Security

public protocol TokenStore: Sendable {
    func loadAccessToken(account: String) throws -> String?
    func saveAccessToken(_ token: String, account: String) throws
    func removeAccessToken(account: String) throws
    func loadTokenRecord(account: String) throws -> OAuthTokenRecord?
    func saveTokenRecord(_ record: OAuthTokenRecord, account: String) throws
}

public enum KeychainError: Error {
    case unexpectedStatus(OSStatus)
}

public struct KeychainTokenStore: TokenStore {
    public static let serviceName = "Codex Watch"
    public static let defaultAccount = "default"

    public init() {}

    public func loadAccessToken(account: String = defaultAccount) throws -> String? {
        if let record = try loadTokenRecord(account: account) {
            return record.accessToken
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func saveAccessToken(_ token: String, account: String = defaultAccount) throws {
        let current = try loadTokenRecord(account: account)
        let record = OAuthTokenRecord(
            accessToken: token,
            refreshToken: current?.refreshToken,
            expiresAt: current?.expiresAt,
            accountId: current?.accountId
        )
        try saveTokenRecord(record, account: account)
    }

    public func saveTokenRecord(_ record: OAuthTokenRecord, account: String = defaultAccount) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(record)
        try removeAccessToken(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public func removeAccessToken(account: String = defaultAccount) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public func loadTokenRecord(account: String = defaultAccount) throws -> OAuthTokenRecord? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else { return nil }

        let decoder = JSONDecoder()
        if let record = try? decoder.decode(OAuthTokenRecord.self, from: data) {
            return record
        }

        if let token = String(data: data, encoding: .utf8), !token.isEmpty {
            return OAuthTokenRecord(accessToken: token, refreshToken: nil, expiresAt: nil, accountId: nil)
        }
        return nil
    }
}
