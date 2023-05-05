import RetryStrategies

public final class RetryPolicyMock<R>: RetryPolicy {
    public typealias BlockResult = R
    public private(set) var inputs = [Result<R, Error>]()

    public init() {}
    
    public var shouldRetryResult = false
    public var shouldRetryResults = [Bool]()

    public func shouldRetry(_ result: Result<R, Error>) -> Bool {
        inputs.append(result)

        guard let retryResult = shouldRetryResults.popLast() else {
            return shouldRetryResult
        }

        return retryResult
    }
}