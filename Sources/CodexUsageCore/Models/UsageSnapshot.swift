import Foundation

public enum UsageWindowKind: String, Sendable {
    case shortWindow
    case weekly
}

public struct UsageWindow: Equatable, Sendable {
    public var kind: UsageWindowKind
    public var label: String
    public var used: Double
    public var limit: Double
    public var resetAt: Date

    public init(kind: UsageWindowKind, label: String, used: Double, limit: Double, resetAt: Date) {
        self.kind = kind
        self.label = label
        self.used = used
        self.limit = limit
        self.resetAt = resetAt
    }

    public var remaining: Double {
        max(limit - used, 0)
    }

    public var usedRatio: Double {
        guard limit > 0 else { return 0 }
        return min(max(used / limit, 0), 1)
    }
}

public struct UsageSnapshot: Equatable, Sendable {
    public var accountEmail: String?
    public var sourceLabel: String
    public var windows: [UsageWindow]
    public var fetchedAt: Date

    public init(accountEmail: String?, sourceLabel: String, windows: [UsageWindow], fetchedAt: Date) {
        self.accountEmail = accountEmail
        self.sourceLabel = sourceLabel
        self.windows = windows
        self.fetchedAt = fetchedAt
    }
}
