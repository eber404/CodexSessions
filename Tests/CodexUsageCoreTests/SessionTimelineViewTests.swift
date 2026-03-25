// Tests/CodexUsageCoreTests/SessionTimelineViewTests.swift
import XCTest
@testable import CodexSessions
@testable import CodexUsageCore

@MainActor
final class SessionTimelineViewTests: XCTestCase {
    func testTimelineRendersBlocks() {
        let scheduler = SessionScheduler()
        let blocks = scheduler.calculateTimelineBlocks(firstHour: 9)
        let view = SessionTimelineView(blocks: blocks, firstHour: 9)
        XCTAssertNotNil(view)
    }
}
