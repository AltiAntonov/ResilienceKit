# Getting Started

Build a retry call by wrapping async work in `Retry { ... }`, configuring the total attempt count, and then calling `run()`.

## Import the package

```swift
import ResilienceKit
```

## Wrap async work

```swift
let result = try await Retry {
    try await fetchProfile()
}
.run()
```

By default, `Retry` performs one attempt.

## Configure total attempts

```swift
let result = try await Retry {
    try await fetchProfile()
}
.maxAttempts(3)
.run()
```

`maxAttempts(_:)` controls the total number of attempts, including the first call. Values below `1` are clamped to `1`.

## Failure behavior

In `0.1.x`, retries happen immediately:

- if an attempt succeeds, `run()` returns that value immediately
- if all attempts fail, `run()` throws the final error
- if the work throws `CancellationError`, `run()` rethrows it without retrying
- delay, backoff, jitter, and retry predicates are intentionally deferred to later releases

## Next steps

- Use the README in the repository root for package-level fit guidance and installation.
- Future releases will layer in delay, backoff, and jitter policies without changing the core `Retry { ... }` entry point.
