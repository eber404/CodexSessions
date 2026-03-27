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
        let intervalSeconds: TimeInterval = 5 * 60 * 60

        task = Task { [weak self] in
            guard let self else { return }

            // Wait until first configured hour
            let waitTime = await self.calculateWaitTime(to: hour, minute: minute)
            let waitHours = waitTime / 3600
            print("SessionKeepAlive: Starting. First ping in \(waitHours) hours (at \(hour):\(String(format: "%02d", minute)))")

            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))

            guard !Task.isCancelled else { return }

            // After first ping, send every 5 hours
            while !Task.isCancelled {
                print("SessionKeepAlive: Sending ping now")
                await self.ping(accessToken: accessToken)

                print("SessionKeepAlive: Next ping in 5 hours")
                guard !Task.isCancelled else { return }
                try? await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
            }
        }
    }

    private func calculateWaitTime(to hour: Int, minute: Int) -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        print("calculateWaitTime: current=\(currentHour):\(String(format: "%02d", currentMinute)), target=\(hour):\(String(format: "%02d", minute))")
        
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let targetToday = calendar.date(from: components) else {
            print("calculateWaitTime: failed to create date, using fallback")
            return TimeInterval(hour * 3600 + minute * 60)
        }

        if targetToday > now {
            let wait = targetToday.timeIntervalSince(now)
            print("calculateWaitTime: today is in future, wait=\(wait)s (\(wait/3600)h)")
            return wait
        }

        components.day! += 1
        guard let targetTomorrow = calendar.date(from: components) else {
            print("calculateWaitTime: failed to create tomorrow date, using fallback")
            return TimeInterval(hour * 3600 + minute * 60)
        }

        let wait = targetTomorrow.timeIntervalSince(now)
        print("calculateWaitTime: tomorrow is in future, wait=\(wait)s (\(wait/3600)h)")
        return wait
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
            print("SessionKeepAlive: Calling client.sendPing with token length: \(accessToken.count)")
            try await client.sendPing(accessToken: accessToken)
            print("SessionKeepAlive: Ping successful!")
        } catch {
            print("SessionKeepAlive: Ping failed with error: \(error)")
        }
    }
}
