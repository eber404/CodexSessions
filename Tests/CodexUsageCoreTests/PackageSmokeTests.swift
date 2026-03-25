import XCTest
@testable import CodexUsageCore

final class PackageSmokeTests: XCTestCase {
    func testCoreModuleLoads() {
        XCTAssertEqual(AppConstants.appName, "CodexSessions")
    }
}
