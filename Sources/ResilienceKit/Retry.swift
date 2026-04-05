//
//  Retry.swift
//  ResilienceKit
//
//  Defines the public retry entry point and fluent configuration surface.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

public struct Retry<Output>: Sendable {
    let operation: @Sendable () async throws -> Output
    let configuration: RetryConfiguration

    public init(
        _ operation: @escaping @Sendable () async throws -> Output
    ) {
        self.operation = operation
        self.configuration = RetryConfiguration()
    }

    public func maxAttempts(_ value: Int) -> Self {
        return Self(
            operation: operation,
            configuration: configuration.updatingMaxAttempts(value)
        )
    }

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
