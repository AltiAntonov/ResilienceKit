//
//  RetryExecutor.swift
//  ResilienceKit
//
//  Runs retry attempts and enforces terminal cancellation behavior.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

package struct RetryExecutor: Sendable {
    package init() {}

    package func run<Output>(
        configuration: RetryConfiguration,
        operation: @escaping @Sendable () async throws -> Output
    ) async throws -> Output {
        for attempt in 1...configuration.maxAttempts {
            try Task.checkCancellation()

            do {
                return try await operation()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                if attempt == configuration.maxAttempts {
                    throw error
                }

                if configuration.delay > .zero {
                    try await Task.sleep(for: configuration.delay)
                }
            }
        }

        preconditionFailure("RetryExecutor exhausted control flow unexpectedly.")
    }
}
