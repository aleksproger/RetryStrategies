import RetryStrategies
import RetryStrategiesTestKit

import XCTest

final class DelayBasedRetryStrategyTests: XCTestCase {
    private lazy var sut = DelayBasedRetryStrategy<Int, RetryPolicyMock>(
        initialDelay: initialDelay,
        maximumDelay: maximumDelay,
        delayMultiplier: delayMultiplier,
        retryPolicy: retryPolicy,
        sleep: sleep.call
    )

    private var initialDelay = 30.0
    private var maximumDelay = 70.0
    private var delayMultiplier = 2.0
    private let retryPolicy = RetryPolicyMock<Int>()
    private let sleep = BlockCallChecker<TimeInterval, Void>(())

    private let callChecker = VoidBlockCallChecker<Result<Int, Error>>(.success(0))
    private let callbackChecker = BlockCallChecker<Result<Int, Error>, Void>(())
    private let asyncCallChecker = AsyncBlockCallChecker<Void, Result<Int, Error>>(.success(0))

    // MARK: Sync Block

    func test_Execute_ReturnResultOfTheBlock() throws {
        retryPolicy.shouldRetryResult = false

        let result = sut.execute(callChecker.call)

        XCTAssertEqual(try result.get(), try callChecker.result.get())
    }

    func test_Execute_InitialDelayIsZero_ExecutesTwiceWithoutSleep() {
        initialDelay = 0
        retryPolicy.shouldRetryResult = true

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(callChecker.count, 2)
        XCTAssertEqual(sleep.count, 0)
    }

    func test_Execute_InitialDelayIsMaximum_ExecutesTwiceWithSleep() {
        initialDelay = 500
        maximumDelay = 500
        retryPolicy.shouldRetryResult = true

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(callChecker.count, 2)
        XCTAssertEqual(sleep.inputs, [maximumDelay])
    }

    func test_Execute_InitialDelayIsLowerThanZero_ExecutesOnesImmediately() {
        initialDelay = -1
        retryPolicy.shouldRetryResult = true

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(callChecker.count, 1)
        XCTAssertEqual(sleep.count, 0)
    }

    func test_Execute_InitialDelayIsEqualToMaximumDelay_ExecutesOnesAfterDelay() {
        initialDelay = 30
        maximumDelay = 30
        retryPolicy.shouldRetryResult = true

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(callChecker.count, 2)
        XCTAssertEqual(sleep.inputs, [30])
    }

    func test_Execute_InitialDelayIsHigherThanMaximumDelay_ExecutesOnesAfterImmediately() {
        initialDelay = 35
        maximumDelay = 30
        retryPolicy.shouldRetryResult = true

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(callChecker.count, 1)
        XCTAssertEqual(sleep.count, 0)
    }

    func test_Execute_RetryPolicyAlwayReturnsTrue_CallsBlockMaximumTimes() {
        initialDelay = 30
        maximumDelay = 70
        retryPolicy.shouldRetryResult = true

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(callChecker.count, 3)
    }

    func test_Execute_RetryPolicyAlwayReturnsTrue_MultipliesDelay() {
        initialDelay = 30
        maximumDelay = 70
        retryPolicy.shouldRetryResult = true

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(sleep.inputs, [30, 60])
    }

    func test_Execute_AsksRetryPolicyOnEachCall_ExceptLast() {
        initialDelay = 30
        maximumDelay = 70
        retryPolicy.shouldRetryResult = true

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(retryPolicy.inputs.count, 2)
    }

    func test_Execute_PolicyReturnFalse_StopsRetrying() {
        maximumDelay = 600
        retryPolicy.shouldRetryResults = [true, false].reversed()

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(callChecker.count, 2)
    }

    func test_Execute_PolicyReturnFalse_AsksPolicyOnEachCall() {
        maximumDelay = 600
        retryPolicy.shouldRetryResults = [true, false].reversed()

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(retryPolicy.inputs.count, 2)
    }

    // MARK: Async Block

    func test_ExecuteAsync_ReturnResultOfTheBlock() throws {
        retryPolicy.shouldRetryResult = false

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(try callbackChecker.inputs.last?.get(), try callChecker.result.get())
    }

    func test_ExecuteAsync_InitialDelayIsZero_ExecutesTwiceWithoutSleep() {
        initialDelay = 0
        retryPolicy.shouldRetryResult = true

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(asyncCallChecker.count, 2)
        XCTAssertEqual(callbackChecker.count, 1)
        XCTAssertEqual(sleep.count, 0)
    }

    func test_ExecuteAsync_InitialDelayIsMaximum_ExecutesTwiceWithSleep() {
        initialDelay = 500
        maximumDelay = 500
        retryPolicy.shouldRetryResult = true

        _ = sut.execute(callChecker.call)

        XCTAssertEqual(callChecker.count, 2)
        XCTAssertEqual(sleep.inputs, [maximumDelay])
    }

    func test_ExecuteAsync_InitialDelayIsLowerThanZero_ExecutesOnesImmediately() {
        initialDelay = -1
        retryPolicy.shouldRetryResult = true

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(callbackChecker.count, 1)
        XCTAssertEqual(sleep.count, 0)
    }

    func test_ExecuteAsync_InitialDelayIsEqualToMaximumDelay_ExecutesOnesAfterDelay() {
        initialDelay = 30
        maximumDelay = 30
        retryPolicy.shouldRetryResult = true

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(callbackChecker.count, 1)
        XCTAssertEqual(sleep.inputs, [30])
    }

    func test_ExecuteAsync_InitialDelayIsHigherThanMaximumDelay_ExecutesOnesImmediately() {
        initialDelay = 35
        maximumDelay = 30
        retryPolicy.shouldRetryResult = true

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(callbackChecker.count, 1)
        XCTAssertEqual(sleep.count, 0)
    }

    func test_ExecuteAsync_RetryPolicyAlwayReturnsTrue_CallsBlockMaximumTimes() {
        initialDelay = 30
        maximumDelay = 70
        retryPolicy.shouldRetryResult = true

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(asyncCallChecker.count, 3)
    }

    func test_ExecuteAsync_RetryPolicyAlwayReturnsTrue_MultipliesDelay() {
        initialDelay = 30
        maximumDelay = 70
        retryPolicy.shouldRetryResult = true

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(sleep.inputs, [30, 60])
    }

    func test_ExecuteAsync_AsksRetryPolicyOnEachCall_ExceptLast() {
        initialDelay = 30
        maximumDelay = 70
        retryPolicy.shouldRetryResult = true

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(retryPolicy.inputs.count, 2)
    }

    func test_ExecuteAsync_PolicyReturnFalse_StopsRetrying() {
        maximumDelay = 600
        retryPolicy.shouldRetryResults = [true, false].reversed()

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(asyncCallChecker.count, 2)
    }

    func test_ExecuteAasync_PolicyReturnFalse_AsksPolicyOnEachCall() {
        maximumDelay = 600
        retryPolicy.shouldRetryResults = [true, false].reversed()

        sut.execute(asyncCallChecker.call, completion: callbackChecker.call)

        XCTAssertEqual(retryPolicy.inputs.count, 2)
    }
}