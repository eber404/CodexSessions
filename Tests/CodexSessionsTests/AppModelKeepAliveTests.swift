import Foundation
import XCTest
@testable import CodexSessions
@testable import CodexUsageCore

@MainActor
final class AppModelKeepAliveTests: XCTestCase {
    func testStartSessionKeepAliveStopsPreviousInstanceBeforeReplacing() async throws {
        let defaults = makeDefaults()
        let loginManager = TestLoginItemManager(isEnabled: false)
        let tokenStore = KeychainTokenStore()
        let oauthSession = OpenAIOAuthSession()
        let factory = TrackingKeepAliveFactory()
        let tokenProvider = StaticKeepAliveTokenProvider()
        let model = AppModel(
            tokenStore: tokenStore,
            oauthSession: oauthSession,
            userDefaults: defaults,
            loginItemManager: loginManager,
            keepAliveFactory: { _ in factory.make() }
        )

        model.isSignedOut = false
        model.keepAliveEnabled = true
        model.startSessionKeepAlive(tokenProvider: tokenProvider)
        model.startSessionKeepAlive(tokenProvider: tokenProvider)
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(factory.instances.count, 2)
        let stopCount = await factory.instances[0].stopCallCount()
        XCTAssertEqual(stopCount, 1)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppModelKeepAliveTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class TrackingKeepAliveFactory {
    private(set) var instances: [TrackingSessionKeepAlive] = []

    func make() -> SessionKeepAliveControlling {
        let instance = TrackingSessionKeepAlive()
        instances.append(instance)
        return instance
    }
}

private actor TrackingSessionKeepAlive: SessionKeepAliveControlling {
    private var stopCount = 0

    func configure(isEnabled: Bool, firstHour: Int, firstMinute: Int) async {}
    func start() async {}
    func stop() {
        stopCount += 1
    }

    func stopCallCount() -> Int {
        stopCount
    }
}

private final class TestLoginItemManager: LoginItemManaging {
    var isEnabled: Bool

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}

private actor StaticKeepAliveTokenProvider: KeepAliveTokenProviding {
    func accessToken() async throws -> String {
        "token"
    }
}
