import Foundation
import XCTest
@testable import CodexWatch

@MainActor
final class AppModelSettingsPersistenceTests: XCTestCase {
    func testRestoreUserSettingsLoadsPersistedRefreshInterval() {
        let defaults = makeDefaults()
        defaults.set(180.0, forKey: "settings.refreshIntervalSeconds")
        let loginManager = StubLoginItemManager(isEnabled: false)
        let model = AppModel(userDefaults: defaults, loginItemManager: loginManager)

        model.restoreUserSettings()

        XCTAssertEqual(model.refreshIntervalSeconds, 180.0)
    }

    func testRestoreUserSettingsUsesDefaultRefreshIntervalWhenMissing() {
        let defaults = makeDefaults()
        let loginManager = StubLoginItemManager(isEnabled: false)
        let model = AppModel(userDefaults: defaults, loginItemManager: loginManager)

        model.restoreUserSettings()

        XCTAssertEqual(model.refreshIntervalSeconds, 300.0)
    }

    func testSetRefreshIntervalPersistsValue() {
        let defaults = makeDefaults()
        let loginManager = StubLoginItemManager(isEnabled: false)
        let model = AppModel(userDefaults: defaults, loginItemManager: loginManager)

        model.setRefreshInterval(minutes: 3)

        XCTAssertEqual(defaults.double(forKey: "settings.refreshIntervalSeconds"), 180.0)
    }

    func testRestoreUserSettingsLoadsLaunchAtLoginFromDefaults() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "settings.launchAtLoginEnabled")
        let loginManager = StubLoginItemManager(isEnabled: false)
        let model = AppModel(userDefaults: defaults, loginItemManager: loginManager)

        model.restoreUserSettings()

        XCTAssertTrue(model.launchAtLoginEnabled)
        XCTAssertEqual(loginManager.setEnabledCalls, [true])
    }

    func testRestoreUserSettingsFallsBackToLoginManagerWhenMissingDefault() {
        let defaults = makeDefaults()
        let loginManager = StubLoginItemManager(isEnabled: true)
        let model = AppModel(userDefaults: defaults, loginItemManager: loginManager)

        model.restoreUserSettings()

        XCTAssertTrue(model.launchAtLoginEnabled)
        XCTAssertEqual(loginManager.setEnabledCalls, [true])
    }

    func testSetLaunchAtLoginEnabledPersistsAndAppliesSetting() {
        let defaults = makeDefaults()
        let loginManager = StubLoginItemManager(isEnabled: false)
        let model = AppModel(userDefaults: defaults, loginItemManager: loginManager)

        model.setLaunchAtLoginEnabled(true)

        XCTAssertTrue(defaults.bool(forKey: "settings.launchAtLoginEnabled"))
        XCTAssertEqual(loginManager.setEnabledCalls, [true])
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppModelSettingsPersistenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class StubLoginItemManager: LoginItemManaging {
    var isEnabled: Bool
    var setEnabledCalls: [Bool] = []

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func setEnabled(_ enabled: Bool) {
        setEnabledCalls.append(enabled)
        isEnabled = enabled
    }
}
