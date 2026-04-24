import Foundation

public enum UsageParserError: Error {
    case invalidPayload
    case missingWindows
}

public struct UsageResponseParser {
    public init() {}

    public func parse(data: Data, sourceLabel: String) throws -> UsageSnapshot {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let root = object as? [String: Any] else {
            throw UsageParserError.invalidPayload
        }

        let email = (root["account"] as? [String: Any])?["email"] as? String
            ?? (root["user"] as? [String: Any])?["email"] as? String
            ?? (root["email"] as? String)

        guard let windowsArray = extractWindows(from: root), !windowsArray.isEmpty else {
            throw UsageParserError.missingWindows
        }

        let windows = windowsArray.map { dictionary in
            let kindString = (
                (dictionary["kind"] as? String)
                    ?? (dictionary["window"] as? String)
                    ?? (dictionary["name"] as? String)
                    ?? (dictionary["label"] as? String)
                    ?? ""
            ).lowercased()
            let kind: UsageWindowKind = kindString.contains("week") ? .weekly : .shortWindow
            let label = (dictionary["label"] as? String)
                ?? (dictionary["name"] as? String)
                ?? (kind == .weekly ? "Weekly" : "Short window")
            let used = Self.toDouble(dictionary["used"]) ?? Self.toDouble(dictionary["usage"]) ?? Self.toDouble(dictionary["consumed"]) ?? 0
            let limit = Self.toDouble(dictionary["limit"]) ?? Self.toDouble(dictionary["quota"]) ?? Self.toDouble(dictionary["max"]) ?? 100
            let reset = Self.parseDate(dictionary["reset_at"])
                ?? Self.parseDate(dictionary["resets_at"])
                ?? Self.parseDate(dictionary["resetAt"])
                ?? Self.parseDate(dictionary["resetsAt"])
                ?? Date()
            let normalizedUsed = used > 0 ? used : (Self.toDouble(dictionary["used_percent"]) ?? 0)
            return UsageWindow(kind: kind, label: label, used: normalizedUsed, limit: limit, resetAt: reset)
        }

        return UsageSnapshot(accountEmail: email, sourceLabel: sourceLabel, windows: windows, fetchedAt: Date())
    }

    private func extractWindows(from root: [String: Any]) -> [[String: Any]]? {
        if let windows = root["windows"] as? [[String: Any]], !windows.isEmpty {
            return windows
        }

        if let data = root["data"] as? [String: Any],
           let windows = data["windows"] as? [[String: Any]],
           !windows.isEmpty {
            return windows
        }

        if let rateLimits = root["rate_limits"] as? [[String: Any]], !rateLimits.isEmpty {
            return rateLimits
        }

        if let rateLimit = root["rate_limit"] as? [String: Any] {
            var result: [[String: Any]] = []

            if let primary = rateLimit["primary_window"] as? [String: Any] {
                var window = primary
                window["kind"] = "short"
                window["label"] = "Daily"
                result.append(window)
            }

            if let secondary = rateLimit["secondary_window"] as? [String: Any] {
                var window = secondary
                window["kind"] = "weekly"
                window["label"] = "Weekly"
                result.append(window)
            }

            if !result.isEmpty {
                return result
            }
        }

        return nil
    }

    private static func toDouble(_ value: Any?) -> Double? {
        switch value {
        case let number as NSNumber:
            return number.doubleValue
        case let string as String:
            return Double(string)
        case let dictionary as [String: Any]:
            return toDouble(dictionary["value"])
        default:
            return nil
        }
    }

    private static func parseDate(_ value: Any?) -> Date? {
        if let unixSeconds = toDouble(value), unixSeconds > 10_000 {
            return Date(timeIntervalSince1970: unixSeconds)
        }
        guard let string = value as? String else { return nil }
        return ISO8601DateFormatter().date(from: string)
    }
}
