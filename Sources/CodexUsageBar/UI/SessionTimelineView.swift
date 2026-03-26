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
        let endHour = firstHour + 24
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

            HStack {
                Text(String(format: "%02d", firstHour))
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%02d", endHour))
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
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
        let endHour = (firstHour + 24) % 24
        return VStack(alignment: .leading, spacing: 8) {
            Text("Session intervals")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                ForEach(blocks) { block in
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

            HStack {
                Text(String(format: "%02d:%02d", firstHour, firstMinute))
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%02d:%02d", endHour, firstMinute))
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
