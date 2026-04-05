import Testing
@testable import ResilienceKit

@Test
func retryConfigurationDefaultsToOneAttempt() {
    let configuration = RetryConfiguration()

    #expect(configuration.maxAttempts == 1)
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
func retryMaxAttemptsClampsValuesBelowOne() {
    for value in [0, -4] {
        let updated = Retry<Int> { 1 }.maxAttempts(value)

        #expect(updated.configuration.maxAttempts == 1)
    }
}
