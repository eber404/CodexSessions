// Tests/CodexUsageCoreTests/SessionSchedulerTests.swift
import XCTest
@testable import CodexUsageCore

final class SessionSchedulerTests: XCTestCase {
    func testCalculateIntervalsFirstHour9() {
        let scheduler = SessionScheduler()
        let intervals = scheduler.calculateIntervals(firstHour: 9, count: 6)
        let hours = intervals.map { Calendar.current.component(.hour, from: $0) }
        XCTAssertEqual(hours, [0, 5, 9, 10, 14, 19])
    }

    func testCalculateNextPingFromNow() {
        let scheduler = SessionScheduler()
        let nextPing = scheduler.calculateNextPing(firstHour: 9)
        let now = Date()
        XCTAssertTrue(nextPing > now, "Next ping should be in the future")
    }

    func testCalculateTimelineBlocks() {
        let scheduler = SessionScheduler()
        let blocks = scheduler.calculateTimelineBlocks(firstHour: 9)
        XCTAssertEqual(blocks.count, 6) // 6 blocks of 5h = 30h covers all intervals
        XCTAssertTrue(blocks.first?.isNext == true) // First block is next
    }
}