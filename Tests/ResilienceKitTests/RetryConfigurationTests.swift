//
//  RetryConfigurationTests.swift
//  ResilienceKitTests
//
//  Verifies retry configuration defaults and attempt-count clamping.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Testing
@testable import ResilienceKit

@Test
func retryConfigurationDefaultsToOneAttempt() {
    let configuration = RetryConfiguration()

    #expect(configuration.maxAttempts == 1)
}

@Test
func retryConfigurationDefaultsToZeroDelay() {
    let configuration = RetryConfiguration()

    #expect(configuration.delay == .zero)
}

@Test
func retryMaxAttemptsReturnsANewRetryWithoutMutatingTheOriginal() {
    let original = Retry<Int> { 1 }
    let updated = original.maxAttempts(3)

    #expect(original.configuration.maxAttempts == 1)
    #expect(updated.configuration.maxAttempts == 3)
    #expect(original.configuration.maxAttempts == 1)
}

@Test
func retryDelayReturnsANewRetryWithoutMutatingTheOriginal() {
    let original = Retry<Int> { 1 }
    let updated = original.delay(.seconds(2))

    #expect(original.configuration.delay == .zero)
    #expect(updated.configuration.delay == .seconds(2))
    #expect(original.configuration.delay == .zero)
}

@Test
func retryMaxAttemptsClampsValuesBelowOne() {
    for value in [0, -4] {
        let updated = Retry<Int> { 1 }.maxAttempts(value)

        #expect(updated.configuration.maxAttempts == 1)
    }
}

@Test
func retryDelayClampsNegativeDurationsToZero() {
    let updated = Retry<Int> { 1 }.delay(.seconds(-1))

    #expect(updated.configuration.delay == .zero)
}

@Test
func retryExponentialBackoffReturnsANewRetryWithoutMutatingTheOriginal() {
    let original = Retry<Int> { 1 }
    let updated = original.exponentialBackoff(
        baseDelay: .milliseconds(100),
        multiplier: 2
    )

    #expect(original.configuration.delay(afterFailedAttempt: 1) == .zero)
    #expect(updated.configuration.delay(afterFailedAttempt: 1) == .milliseconds(100))
    #expect(updated.configuration.delay(afterFailedAttempt: 2) == .milliseconds(200))
    #expect(updated.configuration.delay(afterFailedAttempt: 3) == .milliseconds(400))
}

@Test
func retryExponentialBackoffClampsMultiplierBelowOne() {
    let updated = Retry<Int> { 1 }.exponentialBackoff(
        baseDelay: .milliseconds(100),
        multiplier: 0.5
    )

    #expect(updated.configuration.delay(afterFailedAttempt: 1) == .milliseconds(100))
    #expect(updated.configuration.delay(afterFailedAttempt: 2) == .milliseconds(100))
}

@Test
func retryExponentialBackoffAppliesMaximumDelayBeforeJitter() {
    let updated = Retry<Int> { 1 }.exponentialBackoff(
        baseDelay: .milliseconds(100),
        multiplier: 3,
        maxDelay: .milliseconds(250)
    )

    #expect(updated.configuration.delay(afterFailedAttempt: 1) == .milliseconds(100))
    #expect(updated.configuration.delay(afterFailedAttempt: 2) == .milliseconds(250))
    #expect(updated.configuration.delay(afterFailedAttempt: 3) == .milliseconds(250))
}

@Test
func retryJitterFractionClampsToSupportedRange() {
    #expect(RetryJitter.fraction(-0.2).fraction == 0)
    #expect(RetryJitter.fraction(0.4).fraction == 0.4)
    #expect(RetryJitter.fraction(2).fraction == 1)
}

@Test
func retryExponentialBackoffAppliesBoundedJitter() {
    let updated = Retry<Int> { 1 }.exponentialBackoff(
        baseDelay: .milliseconds(1_000),
        multiplier: 2,
        jitter: .fraction(0.25)
    )

    for _ in 0..<50 {
        let delay = updated.configuration.delay(afterFailedAttempt: 2)

        #expect(delay >= .milliseconds(1_500))
        #expect(delay <= .milliseconds(2_500))
    }
}
