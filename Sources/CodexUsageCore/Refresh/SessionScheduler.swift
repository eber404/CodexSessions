// Sources/CodexUsageCore/Refresh/SessionScheduler.swift
import Foundation

public struct TimeBlock {
    public let startHour: Int
    public let endHour: Int
    public let label: String
    public let isNext: Bool

    public init(startHour: Int, endHour: Int, label: String, isNext: Bool) {
        self.startHour = startHour
        self.endHour = endHour
        self.label = label
        self.isNext = isNext
    }
}

public final class SessionScheduler {
    private let calendar = Calendar.current
    private let intervalHours = 5
    private let timelineBlockCount = 5

    public init() {}

    public func calculateIntervals(firstHour: Int, count: Int) -> [Date] {
        guard (0...23).contains(firstHour), count >= 0 else { return [] }

        var intervals: [Date] = []
        var currentHour = firstHour

        for _ in 0..<count {
            if let date = nextIntervalDate(hour: currentHour) {
                intervals.append(date)
            }
            currentHour = (currentHour + intervalHours) % 24
        }

        return intervals.sorted()
    }

    public func calculateNextPing(firstHour: Int) -> Date {
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        var hoursUntilNext = firstHour - currentHour
        if hoursUntilNext <= 0 {
            hoursUntilNext += 24
        }

        return calendar.date(byAdding: .hour, value: hoursUntilNext, to: now) ?? now
    }

    public func calculateTimelineBlocks(firstHour: Int) -> [TimeBlock] {
        var blocks: [TimeBlock] = []
        var currentHour = firstHour

        for _ in 0..<timelineBlockCount {
            let endHour = (currentHour + intervalHours) % 24
            let isNext = currentHour == firstHour

            let label = String(format: "%02d:00", currentHour)
            let block = TimeBlock(
                startHour: currentHour,
                endHour: endHour,
                label: label,
                isNext: isNext
            )
            blocks.append(block)

            currentHour = (currentHour + intervalHours) % 24
        }

        return blocks
    }

    private func nextIntervalDate(hour: Int) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        components.second = 0

        guard let date = calendar.date(from: components) else { return nil }

        if date <= Date() {
            return calendar.date(byAdding: .day, value: 1, to: date)
        }
        return date
    }
}