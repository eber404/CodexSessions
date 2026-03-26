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

public struct TimeBlockWithMinute: Identifiable {
    public let id = UUID()
    public let startHour: Int
    public let startMinute: Int
    public let endHour: Int
    public let endMinute: Int
    public let label: String
    public let isNext: Bool

    public init(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, label: String, isNext: Bool) {
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.label = label
        self.isNext = isNext
    }
}

public enum SessionState: String {
    case past
    case current
    case future
}

public struct SessionBlock: Identifiable {
    public let id = UUID()
    public let startHour: Int
    public let startMinute: Int
    public let label: String
    public let state: SessionState

    public init(startHour: Int, startMinute: Int, label: String, state: SessionState) {
        self.startHour = startHour
        self.startMinute = startMinute
        self.label = label
        self.state = state
    }
}

public final class SessionScheduler {
    private let calendar = Calendar.current
    private let intervalHours = 5
    private let timelineBlockCount = 6

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
        calculateNextPing(firstHour: firstHour, firstMinute: 0)
    }

    public func calculateNextPing(firstHour: Int, firstMinute: Int) -> Date {
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        var hoursUntilNext = firstHour - currentHour
        var minutesUntilNext = firstMinute - currentMinute

        if minutesUntilNext < 0 {
            minutesUntilNext += 60
            hoursUntilNext -= 1
        }

        if hoursUntilNext < 0 || (hoursUntilNext == 0 && minutesUntilNext <= 0) {
            hoursUntilNext += 24
        }

        var components = DateComponents()
        components.hour = hoursUntilNext
        components.minute = minutesUntilNext

        return calendar.date(byAdding: components, to: now) ?? now
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

    public func calculateTimelineBlocksWithMinutes(firstHour: Int, firstMinute: Int) -> [TimeBlockWithMinute] {
        var blocks: [TimeBlockWithMinute] = []
        var currentHour = firstHour
        let currentMinute = firstMinute

        for i in 0..<timelineBlockCount {
            let isNext = i == 0
            let label: String

            if i == timelineBlockCount - 1 {
                label = String(format: "%02d:%02d", firstHour, firstMinute)
            } else {
                label = String(format: "%02d:%02d", currentHour, currentMinute)
            }

            let block = TimeBlockWithMinute(
                startHour: currentHour,
                startMinute: currentMinute,
                endHour: (currentHour + intervalHours) % 24,
                endMinute: currentMinute,
                label: label,
                isNext: isNext
            )
            blocks.append(block)

            currentHour = (currentHour + intervalHours) % 24
        }

        return blocks
    }

    public func calculateSessionBlocks(firstHour: Int, firstMinute: Int) -> [SessionBlock] {
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        let firstTotalMinutes = firstHour * 60 + firstMinute

        var blocks: [SessionBlock] = []
        var sessionHour = firstHour
        var sessionMinute = firstMinute

        for i in 0..<timelineBlockCount {
            let sessionTotalMinutes = sessionHour * 60 + sessionMinute

            let state: SessionState
            if sessionTotalMinutes < currentTotalMinutes {
                state = .past
            } else if sessionTotalMinutes == currentTotalMinutes {
                state = .current
            } else {
                state = .future
            }

            let label: String
            if i == timelineBlockCount - 1 {
                label = String(format: "%02d:%02d", firstHour, firstMinute)
            } else {
                label = String(format: "%02d:%02d", sessionHour, sessionMinute)
            }

            let block = SessionBlock(
                startHour: sessionHour,
                startMinute: sessionMinute,
                label: label,
                state: state
            )
            blocks.append(block)

            sessionHour = (sessionHour + intervalHours) % 24
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