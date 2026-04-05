package struct RetryConfiguration: Sendable, Equatable {
    package let maxAttempts: Int

    package init() {
        self.init(storedMaxAttempts: 1)
    }

    package func updatingMaxAttempts(_ value: Int) -> Self {
        Self(storedMaxAttempts: max(1, value))
    }

    private init(storedMaxAttempts: Int) {
        self.maxAttempts = storedMaxAttempts
    }
}
