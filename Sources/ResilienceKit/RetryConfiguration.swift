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
    package let delay: Duration

    package init() {
        self.init(storedMaxAttempts: 1, storedDelay: .zero)
    }

    package func updatingMaxAttempts(_ value: Int) -> Self {
        Self(
            storedMaxAttempts: max(1, value),
            storedDelay: delay
        )
    }

    package func updatingDelay(_ value: Duration) -> Self {
        Self(
            storedMaxAttempts: maxAttempts,
            storedDelay: max(.zero, value)
        )
    }

    private init(storedMaxAttempts: Int, storedDelay: Duration) {
        self.maxAttempts = storedMaxAttempts
        self.delay = storedDelay
    }
}
