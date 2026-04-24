// Sources/CodexWatch/UI/SessionTimelineView.swift
import SwiftUI
import CodexWatchCore

public struct SessionTimelineView: View {
    let blocks: [TimeBlock]
    let firstHour: Int

    public init(blocks: [TimeBlock], firstHour: Int) {
        self.blocks = blocks
        self.firstHour = firstHour
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
    let sessionBlocks: [SessionBlock]

    public init(sessionBlocks: [SessionBlock]) {
        self.sessionBlocks = sessionBlocks
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session schedule")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                ForEach(Array(sessionBlocks.enumerated()), id: \.offset) { index, block in
                    let isLast = index == sessionBlocks.count - 1

                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                )

                            Text(block.label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }

                    if !isLast {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
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
