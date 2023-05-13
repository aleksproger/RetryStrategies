import Foundation
import OSLog

private let log = OSLog(subsystem: "com.retry-strategy", category: "attempts-based-retry-strategy")

public final class AttemptsBasedRetryStrategy<R, P: RetryPolicy>: RetryStrategy 
where P.BlockResult == R {
    public typealias BlockResult = R
    public typealias RetryPolicy = P

    private let maximumAttempts: Int
    private let retryPolicy: RetryPolicy

    public init(
        maximumAttempts: Int,
        retryPolicy: RetryPolicy
    ) {
        self.maximumAttempts = maximumAttempts
        self.retryPolicy = retryPolicy
    }

    public func execute(
        _ block: @escaping () -> Result<BlockResult, Error>
    ) -> Result<BlockResult, Error> {
        guard maximumAttempts > 0 else {
            os_log("Will not perform retries as maximumAttempts(%ld) too low", log: log, maximumAttempts)
            return block()
        }

        os_log("Executing retriable block", log: log)
        var result = block()

        for _ in 0..<maximumAttempts {
            guard retryPolicy.shouldRetry(result) else {
                os_log("Will not retry to execute block, due to retryPolicy decision", log: log)
                return result
            }

            os_log("Executing retriable block", log: log)
            result = block()
        }

        return result
    }

    public func execute(
        _ asyncBlock: @escaping (@escaping (Result<BlockResult, Error>) -> Void) -> Void,
        completion: @escaping (Result<BlockResult, Error>) -> Void
    ) {
        guard maximumAttempts > 0 else {
            os_log("Will not perform retries as maximumAttempts(%ld) too low", log: log, maximumAttempts)
            return asyncBlock(completion)
        }

        self.execute(attempt: 1, asyncBlock: asyncBlock, completion: completion)
    }

    private func execute(
        attempt: Int,
        asyncBlock: @escaping (@escaping (Result<BlockResult, Error>) -> Void) -> Void,
        completion: @escaping (Result<BlockResult, Error>) -> Void
    ) {
        guard attempt <= maximumAttempts else {
            os_log("Will perform last retry", log: log)
            return asyncBlock(completion)
        }

        os_log("Executing retriable block", log: log)
        asyncBlock() { result in
            if !self.retryPolicy.shouldRetry(result) {
                os_log("Will not retry to execute block, due to retryPolicy decision", log: log)
                return completion(result)
            }

            self.execute(attempt: attempt + 1, asyncBlock: asyncBlock, completion: completion)
        }
    } 
}
