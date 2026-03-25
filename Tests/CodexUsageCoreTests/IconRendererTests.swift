import XCTest
@testable import CodexUsageCore

final class IconRendererTests: XCTestCase {
    func testIconRendererProducesOuterAndInnerRings() {
        let model = IconRendererModel(shortProgress: 0.5, weeklyProgress: 0.25, isStale: false)
        let rings = IconRenderer().ringLayout(for: model)

        XCTAssertEqual(rings.count, 2)
        XCTAssertEqual(rings[0].name, "weekly")
        XCTAssertEqual(rings[1].name, "short")
        XCTAssertGreaterThan(rings[0].radius, rings[1].radius)
    }

    func testIconRendererKeepsRingsVisibleWhenProgressIsZero() {
        let model = IconRendererModel(shortProgress: 0, weeklyProgress: 0, isStale: false)
        let rings = IconRenderer().ringLayout(for: model)

        XCTAssertGreaterThan(rings[0].sweepAngle, 0)
        XCTAssertGreaterThan(rings[1].sweepAngle, 0)
    }

    func testIconRendererClampsProgressToMaxSweep() {
        let model = IconRendererModel(shortProgress: 10, weeklyProgress: 10, isStale: false)
        let rings = IconRenderer().ringLayout(for: model)

        XCTAssertEqual(rings[0].sweepAngle, rings[0].maxSweep)
        XCTAssertEqual(rings[1].sweepAngle, rings[1].maxSweep)
    }

    func testIconRendererProvidesTrackRingsAtFullSweep() {
        let model = IconRendererModel(shortProgress: 0.3, weeklyProgress: 0.8, isStale: false)
        let progressRings = IconRenderer().ringLayout(for: model)
        let trackRings = IconRenderer().trackLayout(for: model)

        XCTAssertEqual(trackRings.count, 2)
        XCTAssertEqual(trackRings[0].name, "weekly")
        XCTAssertEqual(trackRings[1].name, "short")
        XCTAssertEqual(trackRings[0].sweepAngle, trackRings[0].maxSweep)
        XCTAssertEqual(trackRings[1].sweepAngle, trackRings[1].maxSweep)
        XCTAssertEqual(trackRings[0].radius, progressRings[0].radius)
        XCTAssertEqual(trackRings[1].radius, progressRings[1].radius)
    }

    func testIconRendererRotatesRingsWhileLoading() {
        let model = IconRendererModel(
            shortProgress: 0.5,
            weeklyProgress: 0.5,
            isStale: false,
            isLoading: true,
            rotationDegrees: -45
        )
        let rings = IconRenderer().ringLayout(for: model)

        XCTAssertEqual(rings[0].startAngle, -135)
        XCTAssertEqual(rings[1].startAngle, -135)
    }
}
