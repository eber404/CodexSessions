import Foundation

#if canImport(AppKit)
import AppKit
#endif

public struct IconRendererModel: Sendable {
    public var shortProgress: Double
    public var weeklyProgress: Double
    public var isStale: Bool

    public init(shortProgress: Double, weeklyProgress: Double, isStale: Bool) {
        self.shortProgress = shortProgress
        self.weeklyProgress = weeklyProgress
        self.isStale = isStale
    }
}

public struct IconBar: Equatable, Sendable {
    public var name: String
    public var width: Double
    public var y: Double

    public init(name: String, width: Double, y: Double) {
        self.name = name
        self.width = width
        self.y = y
    }
}

public struct IconRenderer {
    public init() {}

    public func barLayout(for model: IconRendererModel) -> [IconBar] {
        let shortWidth = max(2, 16 * clamped(model.shortProgress))
        let weeklyWidth = max(2, 16 * clamped(model.weeklyProgress))
        return [
            IconBar(name: "short", width: shortWidth, y: 5),
            IconBar(name: "weekly", width: weeklyWidth, y: 11),
        ]
    }

#if canImport(AppKit)
    public func makeImage(for model: IconRendererModel, size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        NSColor.clear.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

        let color = model.isStale ? NSColor.secondaryLabelColor : NSColor.labelColor
        color.setFill()

        for bar in barLayout(for: model) {
            let rect = NSRect(x: 1, y: bar.y, width: bar.width, height: bar.name == "weekly" ? 2 : 4)
            NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1).fill()
        }

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
#endif

    private func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
