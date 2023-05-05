public final class VoidBlockCallChecker<Output> {
    public private(set) var count = 0
    public let result: Output

    public init(_ result: Output) {
        self.result = result
    }

    public func call() -> Output {
        count += 1
        return result
    }
}

public final class AsyncBlockCallChecker<Input, Output> {
    public private(set) var count = 0
    public let result: Output

    public init(_ result: Output) {
        self.result = result
    }

    public func call(
        _ completion: @escaping (Output) -> Void
    ) -> Void {
        count += 1
        completion(result)
    }
}

public final class BlockCallChecker<Input, Output> {
    public private(set) var count = 0
    public private(set) var inputs = [Input]()
    public let result: Output

    public init(_ result: Output) {
        self.result = result
    }

    public func call(_ input: Input) -> Output {
        count += 1
        inputs.append(input)
        return result
    }
}