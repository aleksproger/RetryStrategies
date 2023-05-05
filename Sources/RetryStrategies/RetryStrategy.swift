import Foundation

public protocol RetryStrategy {   
    associatedtype BlockResult
    associatedtype RetryPolicy
    func execute(
        _ block: @escaping () -> Result<BlockResult, Error>
    ) -> Result<BlockResult, Error>

    func execute(
        _ asyncBlock: @escaping (@escaping (Result<BlockResult, Error>) -> Void) -> Void,
        completion: @escaping (Result<BlockResult, Error>) -> Void
    )
}