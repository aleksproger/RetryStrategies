public protocol RetryPolicy {
    associatedtype BlockResult

    func shouldRetry(_ result: Result<BlockResult, Error>) -> Bool
}