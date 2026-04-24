import Foundation
import XCTest
@testable import CodexWatchCore

final class UsageResponseParserTests: XCTestCase {
    func testParserMapsShortAndWeeklyWindows() throws {
        let data = try XCTUnwrap(
            """
            {
              "account": { "email": "user@example.com" },
              "windows": [
                {
                  "kind": "short",
                  "label": "Daily",
                  "used": 12,
                  "limit": 100,
                  "reset_at": "2026-03-24T14:00:00Z"
                },
                {
                  "kind": "weekly",
                  "label": "Weekly",
                  "used": 40,
                  "limit": 500,
                  "reset_at": "2026-03-30T00:00:00Z"
                }
              ]
            }
            """.data(using: .utf8)
        )

        let snapshot = try UsageResponseParser().parse(data: data, sourceLabel: "local")

        XCTAssertEqual(snapshot.accountEmail, "user@example.com")
        XCTAssertEqual(snapshot.windows.count, 2)
        XCTAssertEqual(snapshot.windows.first?.kind, .shortWindow)
        XCTAssertEqual(snapshot.windows.last?.kind, .weekly)
    }

    func testParserThrowsForMissingWindows() throws {
        let data = try XCTUnwrap("{}".data(using: .utf8))

        XCTAssertThrowsError(try UsageResponseParser().parse(data: data, sourceLabel: "local"))
    }

    func testParserSupportsWhamRateLimitShape() throws {
        let data = try XCTUnwrap(
            """
            {
              "email": "user@example.com",
              "rate_limit": {
                "allowed": true,
                "limit_reached": false,
                "primary_window": {
                  "used_percent": 25,
                  "limit_window_seconds": 18000,
                  "reset_after_seconds": 10,
                  "reset_at": 1774810000
                },
                "secondary_window": {
                  "used_percent": 66,
                  "limit_window_seconds": 604800,
                  "reset_after_seconds": 100,
                  "reset_at": 1774820000
                }
              }
            }
            """.data(using: .utf8)
        )

        let snapshot = try UsageResponseParser().parse(data: data, sourceLabel: "local")

        XCTAssertEqual(snapshot.accountEmail, "user@example.com")
        XCTAssertEqual(snapshot.windows.count, 2)
        XCTAssertEqual(snapshot.windows.first?.kind, .shortWindow)
        XCTAssertEqual(snapshot.windows.last?.kind, .weekly)
    }
}
