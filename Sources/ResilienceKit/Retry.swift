//
//  Retry.swift
//  ResilienceKit
//
//  Defines the public retry entry point and fluent configuration surface.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

/// Executes async throwing work with an explicit retry configuration.
public struct Retry<Output>: Sendable {
    let operation: @Sendable () async throws -> Output
    let configuration: RetryConfiguration

    /// Creates a retry wrapper around an async throwing operation.
    public init(
        _ operation: @escaping @Sendable () async throws -> Output
    ) {
        self.operation = operation
        self.configuration = RetryConfiguration()
    }

    /// Sets the total number of attempts, including the first execution.
    ///
    /// Values below `1` are clamped to `1`.
    public func maxAttempts(_ value: Int) -> Self {
        return Self(
            operation: operation,
            configuration: configuration.updatingMaxAttempts(value)
        )
    }

    /// Sets the fixed delay between failed attempts.
    ///
    /// Values below `.zero` are clamped to `.zero`.
    public func delay(_ value: Duration) -> Self {
        return Self(
            operation: operation,
            configuration: configuration.updatingDelay(value)
        )
    }

    /// Sets an exponential backoff delay between failed attempts.
    ///
    /// - Parameters:
    ///   - baseDelay: The first retry delay.
    ///   - multiplier: The growth factor applied after each failed attempt.
    ///   - maxDelay: An optional cap for computed delays.
    ///   - jitter: A bounded random adjustment applied to computed delays.
    public func exponentialBackoff(
        baseDelay: Duration,
        multiplier: Double = 2,
        maxDelay: Duration? = nil,
        jitter: RetryJitter = .none
    ) -> Self {
        return Self(
            operation: operation,
            configuration: configuration.updatingExponentialBackoff(
                baseDelay: baseDelay,
                multiplier: multiplier,
                maxDelay: maxDelay,
                jitter: jitter
            )
        )
    }

    /// Sets the condition that decides whether a non-cancellation error is retried.
    public func retry(
        _ condition: @escaping @Sendable (Error) -> Bool
    ) -> Self {
        return Self(
            operation: operation,
            configuration: configuration.updatingRetryCondition(condition)
        )
    }

    /// Runs the wrapped operation using the current retry configuration.
    ///
    /// Cancellation is terminal. If `delay(_:)` is configured, cancellation
    /// during delay is rethrown without running another attempt.
    public func run() async throws -> Output {
        try await RetryExecutor().run(
            configuration: configuration,
            operation: operation
        )
    }

    init(
        operation: @escaping @Sendable () async throws -> Output,
        configuration: RetryConfiguration
    ) {
        self.operation = operation
        self.configuration = configuration
    }
}
