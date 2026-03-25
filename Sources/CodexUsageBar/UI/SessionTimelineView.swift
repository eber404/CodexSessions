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
        VStack(alignment: .leading, spacing: 8) {
            Text("Timeline de hoje")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                ForEach(0..<blocks.count, id: \.self) { index in
                    let block = blocks[index]
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(block.isNext ? Color.green : Color.blue.opacity(0.6))
                            .frame(height: 24)
                            .cornerRadius(4)

                        Text(block.label)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack {
                Text("00")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Spacer()
                Text("24")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}
