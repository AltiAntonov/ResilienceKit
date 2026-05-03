//
//  RetryDelayStrategy.swift
//  ResilienceKit
//
//  Computes fixed and exponential retry delays.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

package enum RetryDelayStrategy: Sendable, Equatable {
    case fixed(Duration)
    case exponentialBackoff(ExponentialBackoffConfiguration)

    package func delay(afterFailedAttempt attempt: Int) -> Duration {
        switch self {
        case .fixed(let delay):
            delay
        case .exponentialBackoff(let configuration):
            configuration.delay(afterFailedAttempt: attempt)
        }
    }
}

package struct ExponentialBackoffConfiguration: Sendable, Equatable {
    package let baseDelay: Duration
    package let multiplier: Double
    package let maxDelay: Duration?
    package let jitter: RetryJitter

    package init(
        baseDelay: Duration,
        multiplier: Double,
        maxDelay: Duration?,
        jitter: RetryJitter
    ) {
        self.baseDelay = max(.zero, baseDelay)
        self.multiplier = max(1, multiplier)
        self.maxDelay = maxDelay.map { max(.zero, $0) }
        self.jitter = jitter
    }

    package func delay(afterFailedAttempt attempt: Int) -> Duration {
        let exponent = max(0, attempt - 1)
        var seconds = baseDelay.retrySeconds

        for _ in 0..<exponent {
            seconds *= multiplier
        }

        if let maxDelay {
            seconds = min(seconds, maxDelay.retrySeconds)
        }

        guard jitter.fraction > 0, seconds > 0 else {
            return .retrySeconds(seconds)
        }

        let jitterAmount = seconds * jitter.fraction
        let lowerBound = seconds - jitterAmount
        let upperBound = seconds + jitterAmount

        return .retrySeconds(Double.random(in: lowerBound...upperBound))
    }
}

private extension Duration {
    var retrySeconds: Double {
        let components = components
        return Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }

    static func retrySeconds(_ seconds: Double) -> Self {
        guard seconds > 0 else {
            return .zero
        }

        let nanoseconds = seconds * 1_000_000_000

        if nanoseconds >= Double(Int64.max) {
            return .nanoseconds(Int64.max)
        }

        return .nanoseconds(Int64(nanoseconds.rounded()))
    }
}
