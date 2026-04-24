import Foundation

public struct OpenAITokenDecoder {
    public init() {}

    public func decodeAccountID(from jwt: String) -> String? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        let payload = String(parts[1])

        guard let data = decodeBase64URL(payload),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any]
        else {
            return nil
        }

        if let auth = dictionary["https://api.openai.com/auth"] as? [String: Any],
           let accountID = auth["chatgpt_account_id"] as? String,
           !accountID.isEmpty {
            return accountID
        }

        if let sub = dictionary["sub"] as? String, !sub.isEmpty {
            return sub
        }

        return nil
    }

    private func decodeBase64URL(_ value: String) -> Data? {
        var string = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let padding = string.count % 4
        if padding > 0 {
            string += String(repeating: "=", count: 4 - padding)
        }
        return Data(base64Encoded: string)
    }
}
