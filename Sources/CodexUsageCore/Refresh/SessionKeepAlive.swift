import Foundation

public actor SessionKeepAlive {
    private let client: ChatCompletionClientProtocol
    private let intervalSeconds: TimeInterval = 5 * 60 * 60
    private var task: Task<Void, Never>?

    public init(client: ChatCompletionClientProtocol) {
        self.client = client
    }

    public func start(accessToken: String) {
        stop()
        task = Task { [weak self] in
            guard let self else { return }
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

    private func ping(accessToken: String) async {
        do {
            try await client.sendPing(accessToken: accessToken)
        } catch {
            print("SessionKeepAlive ping failed: \(error)")
        }
    }
}
