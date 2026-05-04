//
//  RetryConfiguration.swift
//  ResilienceKit
//
//  Stores internal retry configuration values for execution.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

package struct RetryConfiguration: Sendable {
    package let maxAttempts: Int
    package let delayStrategy: RetryDelayStrategy
    package let retryCondition: @Sendable (Error) -> Bool

    package init() {
        self.init(
            storedMaxAttempts: 1,
            delayStrategy: .fixed(.zero),
            retryCondition: { _ in true }
        )
    }

    package var delay: Duration {
        delay(afterFailedAttempt: 1)
    }

    package func updatingMaxAttempts(_ value: Int) -> Self {
        Self(
            storedMaxAttempts: max(1, value),
            delayStrategy: delayStrategy,
            retryCondition: retryCondition
        )
    }

    package func updatingDelay(_ value: Duration) -> Self {
        Self(
            storedMaxAttempts: maxAttempts,
            delayStrategy: .fixed(max(.zero, value)),
            retryCondition: retryCondition
        )
    }

    package func updatingExponentialBackoff(
        baseDelay: Duration,
        multiplier: Double,
        maxDelay: Duration?,
        jitter: RetryJitter
    ) -> Self {
        Self(
            storedMaxAttempts: maxAttempts,
            delayStrategy: .exponentialBackoff(
                ExponentialBackoffConfiguration(
                    baseDelay: baseDelay,
                    multiplier: multiplier,
                    maxDelay: maxDelay,
                    jitter: jitter
                )
            ),
            retryCondition: retryCondition
        )
    }

    package func delay(afterFailedAttempt attempt: Int) -> Duration {
        delayStrategy.delay(afterFailedAttempt: attempt)
    }

    package func updatingRetryCondition(
        _ condition: @escaping @Sendable (Error) -> Bool
    ) -> Self {
        Self(
            storedMaxAttempts: maxAttempts,
            delayStrategy: delayStrategy,
            retryCondition: condition
        )
    }

    package func shouldRetry(_ error: Error) -> Bool {
        retryCondition(error)
    }

    private init(
        storedMaxAttempts: Int,
        delayStrategy: RetryDelayStrategy,
        retryCondition: @escaping @Sendable (Error) -> Bool
    ) {
        self.maxAttempts = storedMaxAttempts
        self.delayStrategy = delayStrategy
        self.retryCondition = retryCondition
    }
}
