import RetryStrategies
import RetryStrategiesTestKit

import XCTest

final class AttemptsBasedRetryStrategyTests: XCTestCase {
    private lazy var sut = AttemptsBasedRetryStrategy<Int, RetryPolicyMock>(
        maximumAttempts: maximumAttempts,
        retryPolicy: retryPolicy
    )

    private var maximumAttempts = 3
    private let retryPolicy = RetryPolicyMock<Int>()

    private let callChecker = VoidBlockCallChecker<Result<Int, Error>>(.success(0))
    private let callbackChecker = BlockCallChecker<Result<Int, Error>, Void>(())
    private let asyncCallChecker = AsyncBlockCallChecker<Void, Result<Int, Error>>(.success(0))

    // MARK: Sync Block

    func test_Execute_ReturnResultOfTheBlock() throws {
        retryPolicy.shouldRetryResult = false

        let result = sut.execute(callChecker.call)

        XCTAssertEqual(try result.get(), try callChecker.result.get())
    }

    func test_Execute_MaximumAttemptsIsZero_ExecutesOnes() {
        maximumAttempts = 0
        retryPolicy.shouldRetryResult = true

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(callChecker.count, 1)
    }

    func test_Execute_MaximumAttemptsIsLowerThanZero_ExecutesOnes() {
        maximumAttempts = -1
        retryPolicy.shouldRetryResult = true

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(callChecker.count, 1)
    }

    func test_Execute_RetryPolicyAlwayReturnsTrue_CallsBlockOnesPlusMaximumRetries() {
        retryPolicy.shouldRetryResult = true

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(callChecker.count, maximumAttempts + 1)
    }

    func test_Execute_AsksRetryPolicy_OnEachRetry() {
        retryPolicy.shouldRetryResult = true

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(retryPolicy.inputs.count, maximumAttempts)
    }

    func test_Execute_PolicyReturnFalse_StopsRetrying() {
        retryPolicy.shouldRetryResults = [true, false].reversed()

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(callChecker.count, 2)
    }

    func test_Execute_PolicyReturnFalse_AsksPolicyOnEachCall() {
        retryPolicy.shouldRetryResults = [true, false].reversed()

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(retryPolicy.inputs.count, 2)
    }

    // MARK: Async Block

     func test_ExecuteAsunc_ReturnResultOfTheBlock() throws {
        retryPolicy.shouldRetryResult = false

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(try callbackChecker.inputs.last?.get(), 0)
    }

    func test_ExecuteAsync_MaximumAttemptsIsZero_ExecutesOnes() {
        maximumAttempts = 0
        retryPolicy.shouldRetryResult = true

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(asyncCallChecker.count, 1)
    }

    func test_ExecuteAsync_MaximumAttemptsIsLowerThanZero_ExecutesOnes() {
        maximumAttempts = -1
        retryPolicy.shouldRetryResult = true

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(asyncCallChecker.count, 1)
    }

    func test_ExecuteAsync_RetryPolicyAlwayReturnsTrue_CallsBlockOnesPlusMaximumRetries() {
        retryPolicy.shouldRetryResult = true

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(asyncCallChecker.count, maximumAttempts + 1)
    }

    func test_ExecuteAsync_AsksRetryPolicy_OnEachRetryCall() {
        retryPolicy.shouldRetryResult = true

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(retryPolicy.inputs.count, maximumAttempts)
    }

    func test_ExecuteAsync_PolicyReturnFalse_StopsRetrying() {
        retryPolicy.shouldRetryResults = [true, false].reversed()

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(asyncCallChecker.count, 2)
    }

    func test_ExecuteAsync_PolicyReturnFalse_AsksPolicyOnEachCall() {
        retryPolicy.shouldRetryResults = [true, false].reversed()

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(retryPolicy.inputs.count, 2)
    }
}