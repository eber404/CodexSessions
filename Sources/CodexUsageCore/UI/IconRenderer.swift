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

public struct IconRing: Equatable, Sendable {
    public var name: String
    public var radius: Double
    public var lineWidth: Double
    public var startAngle: Double
    public var sweepAngle: Double
    public var maxSweep: Double

    public init(
        name: String,
        radius: Double,
        lineWidth: Double,
        startAngle: Double,
        sweepAngle: Double,
        maxSweep: Double
    ) {
        self.name = name
        self.radius = radius
        self.lineWidth = lineWidth
        self.startAngle = startAngle
        self.sweepAngle = sweepAngle
        self.maxSweep = maxSweep
    }
}

public struct IconRenderer {
    public init() {}

    public func ringLayout(for model: IconRendererModel) -> [IconRing] {
        let startAngle = -90.0
        let maxSweep = 300.0
        let minSweep = 14.0

        let weeklySweep = minSweep + (maxSweep - minSweep) * clamped(model.weeklyProgress)
        let shortSweep = minSweep + (maxSweep - minSweep) * clamped(model.shortProgress)

        return [
            IconRing(
                name: "weekly",
                radius: 7.1,
                lineWidth: 2.3,
                startAngle: startAngle,
                sweepAngle: weeklySweep,
                maxSweep: maxSweep
            ),
            IconRing(
                name: "short",
                radius: 4.2,
                lineWidth: 2.2,
                startAngle: startAngle,
                sweepAngle: shortSweep,
                maxSweep: maxSweep
            ),
        ]
    }

#if canImport(AppKit)
    public func makeImage(for model: IconRendererModel, size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        NSColor.clear.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

        let color = model.isStale ? NSColor.secondaryLabelColor : NSColor.labelColor
        color.setStroke()

        let center = NSPoint(x: size / 2, y: size / 2)

        for ring in ringLayout(for: model) {
            let path = NSBezierPath()
            path.appendArc(
                withCenter: center,
                radius: CGFloat(ring.radius),
                startAngle: CGFloat(ring.startAngle),
                endAngle: CGFloat(ring.startAngle - ring.sweepAngle),
                clockwise: true
            )
            path.lineWidth = CGFloat(ring.lineWidth)
            path.lineCapStyle = .round
            path.stroke()
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
