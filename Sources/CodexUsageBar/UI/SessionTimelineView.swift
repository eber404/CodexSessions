// Sources/CodexUsageBar/UI/SessionTimelineView.swift
import SwiftUI
import CodexUsageCore

public struct SessionTimelineView: View {
    let blocks: [TimeBlock]
    let firstHour: Int

    public init(blocks: [TimeBlock], firstHour: Int) {
        self.blocks = blocks
        self.firstHour = firstHour
    }

    public var body: some View {
        timelineView
    }

    private var timelineView: some View {
        return VStack(alignment: .leading, spacing: 8) {
            Text("Today's timeline")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                ForEach(0..<blocks.count, id: \.self) { index in
                    let block = blocks[index]
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(block.isNext ? Color.green : Color.blue.opacity(0.6))
                            .frame(height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text(block.label)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

public struct SessionTimelineViewWithMinutes: View {
    let blocks: [TimeBlockWithMinute]
    let firstHour: Int
    let firstMinute: Int

    public init(blocks: [TimeBlockWithMinute], firstHour: Int, firstMinute: Int) {
        self.blocks = blocks
        self.firstHour = firstHour
        self.firstMinute = firstMinute
    }

    public var body: some View {
        timelineViewWithMinutes
    }

    private var timelineViewWithMinutes: some View {
        return VStack(alignment: .leading, spacing: 8) {
            Text("Session intervals")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                    let isFirst = index == 0
                    let isLast = index == blocks.count - 1
                    let isCompleted = !block.isNext

                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isCompleted ? Color.green : Color.clear)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isCompleted ? Color.green : Color.gray.opacity(0.4), lineWidth: 2)
                                        .frame(width: 40, height: 40)
                                )

                            Text(block.label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(isCompleted ? .white : .secondary)
                        }

                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                        } else {
                            Circle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }

                    if !isLast {
                        Rectangle()
                            .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
