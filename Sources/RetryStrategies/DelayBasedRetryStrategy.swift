import Foundation
import OSLog

private let log = OSLog(subsystem: "com.f-secure.safe", category: "delay-based-retry-strategy")

public final class DelayBasedRetryStrategy<R, P: RetryPolicy>: RetryStrategy 
where P.BlockResult == R {
    public typealias BlockResult = R
    public typealias RetryPolicy = P

    private let initialDelay: TimeInterval
    private let maximumDelay: TimeInterval
    private let delayMultiplier: Double
    private let retryPolicy: RetryPolicy
    private let sleep: (TimeInterval) -> Void 

    public init(
        initialDelay: TimeInterval,
        maximumDelay: TimeInterval,
        delayMultiplier: Double,
        retryPolicy: RetryPolicy,
        sleep: @escaping (TimeInterval) -> Void = { time in Thread.sleep(forTimeInterval: time) }
    ) {
        self.initialDelay = initialDelay
        self.maximumDelay = maximumDelay
        self.delayMultiplier = delayMultiplier
        self.retryPolicy = retryPolicy
        self.sleep = sleep
    }

    public func execute(
        _ block: @escaping () -> Result<BlockResult, Error>
    ) -> Result<BlockResult, Error> {
        guard initialDelay >= 0, initialDelay <= maximumDelay else {
            os_log("Executing retriable block", log: log)
            return block()
        }

        os_log("Executing retriable block", log: log)
        var delay = initialDelay
        var result = block()

        if delay == 0 {
            guard retryPolicy.shouldRetry(result) else {
                os_log("Will not retry to execute block, due to retryPolicy decision", log: log)
                return result
            }

            return block()
        }

        while (initialDelay...maximumDelay).contains(delay) {
            guard retryPolicy.shouldRetry(result) else {
                os_log("Will not retry to execute block, due to retryPolicy decision", log: log)
                return result
            }

            os_log("Will perform retry. Sleep for %{public}d, before retry", log: log, delay)
            sleep(delay)

            os_log("Executing retriable block", log: log)
            result = block()
            delay *= delayMultiplier
        }

        return result
    }

    public func execute(
        _ asyncBlock: @escaping (@escaping (Result<BlockResult, Error>) -> Void) -> Void,
        completion: @escaping (Result<BlockResult, Error>) -> Void
    ) {
        self.execute(delay: self.initialDelay, asyncBlock: asyncBlock, completion: completion)
    }

    private func execute(
        delay: TimeInterval,
        asyncBlock: @escaping (@escaping (Result<BlockResult, Error>) -> Void) -> Void,
        completion: @escaping (Result<BlockResult, Error>) -> Void
    ) {
        os_log("Executing retriable block", log: log)
        asyncBlock() { result in
            guard delay >= 0, delay <= self.maximumDelay else {
                os_log("Executing retriable block", log: log)
                return completion(result)
            }

            if !self.retryPolicy.shouldRetry(result) {
                os_log("Will not retry to execute block, due to retryPolicy decision", log: log)
                return completion(result)
            }

            if delay == 0 {
                os_log("Executing retriable block", log: log)
                return asyncBlock(completion)
            }

            os_log("Will perform retry. Sleep for %{public}d, before retry", log: log, delay)
            self.sleep(delay)

            self.execute(
                delay: delay * self.delayMultiplier,
                asyncBlock: asyncBlock,
                completion: completion
            )
        }
    } 
}
