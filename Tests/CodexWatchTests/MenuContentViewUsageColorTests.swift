import XCTest
@testable import CodexWatch

final class MenuContentViewUsageColorTests: XCTestCase {
    func testUsageColorThresholds() {
        XCTAssertEqual(UsageBarThresholdColor.forRatio(0.79), .green)
        XCTAssertEqual(UsageBarThresholdColor.forRatio(0.80), .orange)
        XCTAssertEqual(UsageBarThresholdColor.forRatio(0.89), .orange)
        XCTAssertEqual(UsageBarThresholdColor.forRatio(0.90), .red)
        XCTAssertEqual(UsageBarThresholdColor.forRatio(1.0), .red)
    }
}
