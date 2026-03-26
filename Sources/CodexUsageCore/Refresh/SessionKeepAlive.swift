import Foundation

public actor SessionKeepAlive {
    private let client: ChatCompletionClientProtocol
    private let intervalSeconds: TimeInterval = 5 * 60 * 60
    private var task: Task<Void, Never>?
    private var isEnabled: Bool = false
    private var firstHour: Int = 9
    private var firstMinute: Int = 0

    public init(client: ChatCompletionClientProtocol) {
        self.client = client
    }

    public func configure(isEnabled: Bool, firstHour: Int, firstMinute: Int = 0) {
        self.isEnabled = isEnabled
        self.firstHour = firstHour
        self.firstMinute = firstMinute
    }

    public func start(accessToken: String) {
        stop()
        guard isEnabled else { return }

        let waitTime = timeUntilFirstHour()

        task = Task { [weak self] in
            guard let self else { return }

            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))

            guard !Task.isCancelled else { return }

            while !Task.isCancelled {
                await self.ping(accessToken: accessToken)
                try? await Task.sleep(nanoseconds: UInt64(self.intervalSeconds * 1_000_000_000))
            }
        }
    }

    public func stop() {
        task?.cancel()
        task = nil
    }

    public var isRunning: Bool {
        task != nil && !task!.isCancelled
    }

    private func timeUntilFirstHour() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        var hoursUntil = self.firstHour - currentHour
        var minutesUntil = self.firstMinute - currentMinute

        if minutesUntil < 0 {
            minutesUntil += 60
            hoursUntil -= 1
        }

        if hoursUntil < 0 || (hoursUntil == 0 && minutesUntil <= 0) {
            hoursUntil += 24
        }

        return TimeInterval(hoursUntil * 3600 + minutesUntil * 60)
    }

    private func ping(accessToken: String) async {
        do {
            try await client.sendPing(accessToken: accessToken)
        } catch {
            print("SessionKeepAlive ping failed: \(error)")
        }
    }
}
