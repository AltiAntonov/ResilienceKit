//
//  RetryBasicTests.swift
//  ResilienceKitTests
//
//  Verifies first-release retry execution and cancellation behavior.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Testing
@testable import ResilienceKit

actor Counter {
    private var value = 0

    func increment() -> Int {
        value += 1
        return value
    }

    func currentValue() -> Int {
        value
    }
}

enum SampleError: Error, Equatable {
    case transient
    case permanent
}

enum SelectiveRetryError: Error, Equatable {
    case retryable
    case notRetryable
}

@Test
func runReturnsSuccessfulValueOnFirstAttempt() async throws {
    let counter = Counter()

    let result = try await Retry {
        _ = await counter.increment()
        return 42
    }
    .run()

    #expect(result == 42)
    #expect(await counter.currentValue() == 1)
}

@Test
func runThrowsCancellationErrorWithoutInvokingOperationWhenTaskIsAlreadyCancelled() async throws {
    actor InvocationCounter {
        private var value = 0

        func increment() {
            value += 1
        }

        func currentValue() -> Int {
            value
        }
    }

    let counter = InvocationCounter()

    enum Outcome {
        case cancelled
        case unexpectedSuccess
        case failed(Error)
    }

    let outcome = await Task.detached { () -> Outcome in
        withUnsafeCurrentTask { $0?.cancel() }

        do {
            _ = try await Retry {
                await counter.increment()
                return 1
            }
            .maxAttempts(3)
            .run()

            return .unexpectedSuccess
        } catch is CancellationError {
            return .cancelled
        } catch {
            return .failed(error)
        }
    }.value

    switch outcome {
    case .cancelled:
        break
    case .unexpectedSuccess:
        Issue.record("Expected Retry.run() to throw when the task is already cancelled")
    case .failed(let error):
        Issue.record("Expected CancellationError, got \(error)")
    }

    #expect(await counter.currentValue() == 0)
}

@Test
func runRetriesUntilOperationSucceeds() async throws {
    let counter = Counter()

    let result = try await Retry {
        let attempt = await counter.increment()
        if attempt < 3 {
            throw SampleError.transient
        }

        return 99
    }
    .maxAttempts(5)
    .run()

    #expect(result == 99)
    #expect(await counter.currentValue() == 3)
}

@Test
func runRetriesErrorsMatchingRetryConditionUntilSuccess() async throws {
    let counter = Counter()

    let result = try await Retry {
        let attempt = await counter.increment()
        if attempt < 3 {
            throw SelectiveRetryError.retryable
        }

        return 100
    }
    .maxAttempts(5)
    .retry { error in
        error as? SelectiveRetryError == .retryable
    }
    .run()

    #expect(result == 100)
    #expect(await counter.currentValue() == 3)
}

@Test
func runThrowsNonRetryableErrorWithoutRetrying() async throws {
    let counter = Counter()

    do {
        _ = try await Retry {
            _ = await counter.increment()
            throw SelectiveRetryError.notRetryable
        }
        .maxAttempts(5)
        .retry { error in
            error as? SelectiveRetryError == .retryable
        }
        .run()

        Issue.record("Expected Retry.run() to throw non-retryable error immediately")
    } catch let error as SelectiveRetryError {
        #expect(error == .notRetryable)
    } catch {
        Issue.record("Expected SelectiveRetryError, got \(error)")
    }

    #expect(await counter.currentValue() == 1)
}

@Test
func runSkipsConfiguredDelayForNonRetryableError() async throws {
    let counter = Counter()
    let clock = ContinuousClock()
    let start = clock.now

    do {
        _ = try await Retry {
            _ = await counter.increment()
            throw SelectiveRetryError.notRetryable
        }
        .maxAttempts(5)
        .delay(.milliseconds(250))
        .retry { error in
            error as? SelectiveRetryError == .retryable
        }
        .run()

        Issue.record("Expected Retry.run() to throw non-retryable error immediately")
    } catch let error as SelectiveRetryError {
        #expect(error == .notRetryable)
    } catch {
        Issue.record("Expected SelectiveRetryError, got \(error)")
    }

    let elapsed = start.duration(to: clock.now)

    #expect(await counter.currentValue() == 1)
    #expect(elapsed < .milliseconds(150))
}

@Test
func runAppliesConfiguredDelayBeforeRetryingUntilSuccess() async throws {
    let counter = Counter()
    let clock = ContinuousClock()
    let start = clock.now

    let result = try await Retry {
        let attempt = await counter.increment()
        if attempt < 2 {
            throw SampleError.transient
        }

        return 7
    }
    .maxAttempts(3)
    .delay(.milliseconds(200))
    .run()

    let elapsed = start.duration(to: clock.now)

    #expect(result == 7)
    #expect(await counter.currentValue() == 2)
    #expect(elapsed >= .milliseconds(150))
}

@Test
func runAppliesExponentialBackoffBeforeRetryingUntilSuccess() async throws {
    let counter = Counter()
    let clock = ContinuousClock()
    let start = clock.now

    let result = try await Retry {
        let attempt = await counter.increment()
        if attempt < 3 {
            throw SampleError.transient
        }

        return 8
    }
    .maxAttempts(3)
    .exponentialBackoff(
        baseDelay: .milliseconds(100),
        multiplier: 2
    )
    .run()

    let elapsed = start.duration(to: clock.now)

    #expect(result == 8)
    #expect(await counter.currentValue() == 3)
    #expect(elapsed >= .milliseconds(250))
}

@Test
func runInvokesOperationExactlyConfiguredNumberOfTimesOnPersistentFailure() async throws {
    let counter = Counter()

    do {
        _ = try await Retry {
            _ = await counter.increment()
            throw SampleError.permanent
        }
        .maxAttempts(4)
        .run()

        Issue.record("Expected Retry.run() to throw after exhausting attempts")
    } catch let error as SampleError {
        #expect(error == .permanent)
    }

    #expect(await counter.currentValue() == 4)
}

@Test
func runDoesNotApplyTrailingDelayAfterFinalFailure() async throws {
    let counter = Counter()
    let clock = ContinuousClock()
    let start = clock.now

    do {
        _ = try await Retry {
            _ = await counter.increment()
            throw SampleError.permanent
        }
        .maxAttempts(2)
        .delay(.milliseconds(250))
        .run()

        Issue.record("Expected Retry.run() to throw after exhausting delayed attempts")
    } catch let error as SampleError {
        #expect(error == .permanent)
    }

    let elapsed = start.duration(to: clock.now)

    #expect(await counter.currentValue() == 2)
    #expect(elapsed >= .milliseconds(200))
    #expect(elapsed < .milliseconds(450))
}

@Test
func runRethrowsCancellationWithoutRetrying() async throws {
    let counter = Counter()

    do {
        _ = try await Retry {
            _ = await counter.increment()
            throw CancellationError()
        }
        .maxAttempts(5)
        .run()

        Issue.record("Expected Retry.run() to rethrow cancellation")
    } catch is CancellationError {
    } catch {
        Issue.record("Expected CancellationError, got \(error)")
    }

    #expect(await counter.currentValue() == 1)
}

@Test
func runStopsBeforeNextAttemptWhenTaskIsCancelledAfterFailure() async throws {
    let counter = Counter()

    enum Outcome {
        case cancelled
        case unexpectedSuccess
        case failed(Error)
    }

    let outcome = await Task { () -> Outcome in
        do {
            _ = try await Retry {
                _ = await counter.increment()
                withUnsafeCurrentTask { $0?.cancel() }
                throw SampleError.transient
            }
            .maxAttempts(3)
            .run()

            return .unexpectedSuccess
        } catch is CancellationError {
            return .cancelled
        } catch {
            return .failed(error)
        }
    }.value

    switch outcome {
    case .cancelled:
        break
    case .unexpectedSuccess:
        Issue.record("Expected Retry.run() to stop after task cancellation")
    case .failed(let error):
        Issue.record("Expected CancellationError, got \(error)")
    }

    #expect(await counter.currentValue() == 1)
}

@Test
func runRethrowsCancellationDuringConfiguredDelayWithoutRetryingAgain() async throws {
    let counter = Counter()

    enum Outcome {
        case cancelled
        case unexpectedSuccess
        case failed(Error)
    }

    let task = Task { () -> Outcome in
        do {
            _ = try await Retry {
                _ = await counter.increment()
                throw SampleError.transient
            }
            .maxAttempts(3)
            .delay(.seconds(5))
            .run()

            return .unexpectedSuccess
        } catch is CancellationError {
            return .cancelled
        } catch {
            return .failed(error)
        }
    }

    try await Task.sleep(for: .milliseconds(150))
    task.cancel()

    let outcome = await task.value

    switch outcome {
    case .cancelled:
        break
    case .unexpectedSuccess:
        Issue.record("Expected Retry.run() to be cancelled during delay")
    case .failed(let error):
        Issue.record("Expected CancellationError, got \(error)")
    }

    #expect(await counter.currentValue() == 1)
}
