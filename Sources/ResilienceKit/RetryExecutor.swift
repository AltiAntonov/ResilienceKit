package struct RetryExecutor: Sendable {
    package init() {}

    package func run<Output>(
        configuration: RetryConfiguration,
        operation: @escaping @Sendable () async throws -> Output
    ) async throws -> Output {
        var lastError: Error?

        for attempt in 1...configuration.maxAttempts {
            if Task.isCancelled {
                throw CancellationError()
            }

            do {
                return try await operation()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error

                if attempt == configuration.maxAttempts {
                    throw error
                }
            }
        }

        throw lastError!
    }
}
