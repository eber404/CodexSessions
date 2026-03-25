import XCTest
@testable import CodexUsageCore

final class IconRendererTests: XCTestCase {
    func testIconRendererProducesTopAndBottomBars() {
        let model = IconRendererModel(shortProgress: 0.5, weeklyProgress: 0.25, isStale: false)
        let bars = IconRenderer().barLayout(for: model)

        XCTAssertEqual(bars.count, 2)
        XCTAssertEqual(bars[0].name, "short")
        XCTAssertEqual(bars[1].name, "weekly")
    }

    func testIconRendererKeepsBarsVisibleWhenProgressIsZero() {
        let model = IconRendererModel(shortProgress: 0, weeklyProgress: 0, isStale: false)
        let bars = IconRenderer().barLayout(for: model)

        XCTAssertGreaterThan(bars[0].width, 0)
        XCTAssertGreaterThan(bars[1].width, 0)
    }
}
