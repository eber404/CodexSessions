import Foundation

public actor SessionKeepAlive {
    private let client: ChatCompletionClientProtocol
    private let intervalHours = 5
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

        let hour = firstHour
        let minute = firstMinute

        task = Task { [weak self] in
            guard let self else { return }

            let waitTime = await self.calculateWaitTime(to: hour, minute: minute)
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))

            guard !Task.isCancelled else { return }

            while !Task.isCancelled {
                await self.ping(accessToken: accessToken)

                let sleepTime = await self.calculateWaitTime(to: hour, minute: minute)
                guard !Task.isCancelled else { return }
                try? await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000_000))
            }
        }
    }

    private func calculateWaitTime(to hour: Int, minute: Int) -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let targetToday = calendar.date(from: components) else {
            return TimeInterval(hour * 3600 + minute * 60)
        }

        if targetToday > now {
            return targetToday.timeIntervalSince(now)
        }

        components.day! += 1
        guard let targetTomorrow = calendar.date(from: components) else {
            return TimeInterval(hour * 3600 + minute * 60)
        }

        return targetTomorrow.timeIntervalSince(now)
    }

    public func stop() {
        task?.cancel()
        task = nil
    }

    public var isRunning: Bool {
        task != nil && !task!.isCancelled
    }

    private func ping(accessToken: String) async {
        do {
            try await client.sendPing(accessToken: accessToken)
        } catch {
            print("SessionKeepAlive ping failed: \(error)")
        }
    }
}
