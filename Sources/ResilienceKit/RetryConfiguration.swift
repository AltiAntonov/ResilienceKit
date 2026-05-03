//
//  RetryConfiguration.swift
//  ResilienceKit
//
//  Stores internal retry configuration values for execution.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

package struct RetryConfiguration: Sendable, Equatable {
    package let maxAttempts: Int
    package let delayStrategy: RetryDelayStrategy

    package init() {
        self.init(storedMaxAttempts: 1, delayStrategy: .fixed(.zero))
    }

    package var delay: Duration {
        delay(afterFailedAttempt: 1)
    }

    package func updatingMaxAttempts(_ value: Int) -> Self {
        Self(
            storedMaxAttempts: max(1, value),
            delayStrategy: delayStrategy
        )
    }

    package func updatingDelay(_ value: Duration) -> Self {
        Self(
            storedMaxAttempts: maxAttempts,
            delayStrategy: .fixed(max(.zero, value))
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
            )
        )
    }

    package func delay(afterFailedAttempt attempt: Int) -> Duration {
        delayStrategy.delay(afterFailedAttempt: attempt)
    }

    private init(storedMaxAttempts: Int, delayStrategy: RetryDelayStrategy) {
        self.maxAttempts = storedMaxAttempts
        self.delayStrategy = delayStrategy
    }
}
