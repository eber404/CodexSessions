import Foundation

public protocol KeepAliveTokenProviding: Sendable {
    func accessToken() async throws -> String
}

public protocol SessionKeepAliveControlling: Actor {
    func configure(isEnabled: Bool, firstHour: Int, firstMinute: Int) async
    func start() async
    func stop()
}

public actor SessionKeepAlive {
    private let client: KeepAliveClientProtocol
    private let tokenProvider: KeepAliveTokenProviding
    private let intervalHours = 5
    private var task: Task<Void, Never>?
    private var isEnabled: Bool = false
    private var firstHour: Int = 9
    private var firstMinute: Int = 0

    public init(client: KeepAliveClientProtocol, tokenProvider: KeepAliveTokenProviding) {
        self.client = client
        self.tokenProvider = tokenProvider
    }

    public func configure(isEnabled: Bool, firstHour: Int, firstMinute: Int = 0) {
        self.isEnabled = isEnabled
        self.firstHour = firstHour
        self.firstMinute = firstMinute
    }

    public func start() {
        stop()
        guard isEnabled else { return }

        let firstPingHour = firstHour
        let firstPingMinute = firstMinute
        let intervalSeconds: TimeInterval = 5 * 60 * 60

        task = Task { [weak self] in
            guard let self else { return }

            // Calculate first ping time - find next 5h interval from now
            let waitTime = await self.calculateNextIntervalTime(fromHour: firstPingHour, fromMinute: firstPingMinute)
            let waitHours = waitTime / 3600
            let waitMinutes = (waitTime.truncatingRemainder(dividingBy: 3600)) / 60
            print("SessionKeepAlive: Starting. First ping in \(Int(waitHours))h \(Int(waitMinutes))m")

            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))

            guard !Task.isCancelled else { return }

            // After first ping, send every 5 hours
            while !Task.isCancelled {
                print("SessionKeepAlive: Sending ping now")
                await self.ping()

                print("SessionKeepAlive: Next ping in 5 hours")
                guard !Task.isCancelled else { return }
                try? await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
            }
        }
    }

    /// Calculate time until next 5-hour interval based on firstHour
    /// Finds the next occurrence of (firstHour + n*5h) from now
    private func calculateNextIntervalTime(fromHour: Int, fromMinute: Int) -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // Calculate total minutes from midnight for current time and first hour
        let currentTotalMinutes = currentHour * 60 + currentMinute
        let firstTotalMinutes = fromHour * 60 + fromMinute
        
        // Find the next interval by adding 5h repeatedly
        var nextTotalMinutes: Int
        var daysToAdd = 0
        
        if firstTotalMinutes > currentTotalMinutes {
            // First hour hasn't passed yet today
            nextTotalMinutes = firstTotalMinutes
        } else {
            // First hour already passed, add 5h intervals until we find a future time
            nextTotalMinutes = firstTotalMinutes
            while nextTotalMinutes <= currentTotalMinutes {
                nextTotalMinutes += 5 * 60
            }
            // If we've gone past midnight (24*60 = 1440), we need to add a day
            if nextTotalMinutes >= 24 * 60 {
                nextTotalMinutes -= 24 * 60
                daysToAdd = 1
            }
        }
        
        // Convert back to hours and minutes
        let nextHour = nextTotalMinutes / 60
        let nextMinute = nextTotalMinutes % 60
        
        print("calculateNextInterval: current=\(currentHour):\(String(format: "%02d", currentMinute)), firstHour=\(fromHour):\(String(format: "%02d", fromMinute)), next=\(nextHour):\(String(format: "%02d", nextMinute)), daysToAdd=\(daysToAdd)")
        
        // Calculate actual wait time
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = nextHour
        components.minute = nextMinute
        components.second = 0
        components.day! += daysToAdd
        
        guard let targetDate = calendar.date(from: components) else {
            return 5 * 60 * 60 // fallback to 5 hours
        }
        
        return targetDate.timeIntervalSince(now)
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

    public func pingForTesting() async {
        await ping()
    }

    private func ping() async {
        do {
            let accessToken = try await tokenProvider.accessToken()
            print("SessionKeepAlive: Calling client.sendPing with token length: \(accessToken.count)")
            try await client.sendPing(accessToken: accessToken)
            print("SessionKeepAlive: Ping successful!")
        } catch {
            print("SessionKeepAlive: Ping failed with error: \(error)")
        }
    }
}

extension SessionKeepAlive: SessionKeepAliveControlling {}
