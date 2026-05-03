//
//  RetryJitter.swift
//  ResilienceKit
//
//  Defines bounded jitter options for retry delay strategies.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

/// A bounded random adjustment applied to computed retry delays.
public struct RetryJitter: Sendable, Equatable {
    /// No jitter.
    public static let none = Self(fraction: 0)

    /// Creates jitter bounded by a fraction of the computed delay.
    ///
    /// Values below `0` are clamped to `0`. Values above `1` are clamped to `1`.
    public static func fraction(_ value: Double) -> Self {
        Self(fraction: min(max(value, 0), 1))
    }

    public let fraction: Double
}
