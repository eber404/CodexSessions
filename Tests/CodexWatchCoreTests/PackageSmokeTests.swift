import XCTest
@testable import CodexWatchCore

final class PackageSmokeTests: XCTestCase {
    func testCoreModuleLoads() {
        XCTAssertEqual(AppConstants.appName, "Codex Watch")
    }
}
