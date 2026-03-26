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
        return VStack(alignment: .leading, spacing: 12) {
            Text("Session intervals")
                .font(.caption)
                .foregroundColor(.secondary)

            GeometryReader { geometry in
                let blockWidth = geometry.size.width / CGFloat(blocks.count)

                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .clipShape(Capsule())

                    HStack(spacing: 0) {
                        ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                            let isFirst = index == 0
                            let isLast = index == blocks.count - 1

                            Circle()
                                .fill(block.isNext ? Color.green : Color.blue)
                                .frame(width: block.isNext ? 16 : 12, height: block.isNext ? 16 : 12)
                                .shadow(color: block.isNext ? Color.green.opacity(0.5) : .clear, radius: block.isNext ? 6 : 0)
                                .offset(x: CGFloat(index) * blockWidth + blockWidth / 2 - (block.isNext ? 8 : 6))
                        }
                    }

                    HStack(spacing: 0) {
                        ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                            let isFirst = index == 0
                            let isLast = index == blocks.count - 1

                            Text(block.label)
                                .font(.system(size: 9, weight: block.isNext ? .semibold : .regular))
                                .foregroundColor(block.isNext ? .primary : .secondary)
                                .frame(width: blockWidth)
                                .offset(x: CGFloat(index) * blockWidth)
                        }
                    }
                    .offset(y: 18)
                }
            }
            .frame(height: 44)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
