import RetryStrategies

public final class RetryStrategyMock<R, P: RetryPolicy>: RetryStrategy 
where P.BlockResult == R {
    public typealias BlockResult = R
    public typealias RetryPolicy = P

    public private(set) var blocks = [() -> Result<R, Error>]()
    public private(set) var asyncBlocks = [(@escaping (Result<R, Error>) -> Void) -> Void]()
    public private(set) var completions = [(Result<R, Error>) -> Void]()

    public var result = Result<R, Error>.failure(MockError())

    public init() {}
    
   public  func execute(
        _ block: @escaping () -> Result<R, Error>
    ) -> Result<R, Error> {
        blocks.append(block)
        return result
    }

    public func execute(
        _ asyncBlock: @escaping (@escaping (Result<R, Error>) -> Void) -> Void,
        completion: @escaping (Result<R, Error>) -> Void
    ) {
        asyncBlocks.append(asyncBlock)
        completions.append(completion)
        completion(result)
    }
}

private struct MockError: Error {}
