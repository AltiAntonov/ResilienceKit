# ResilienceKit

`ResilienceKit` is a small Swift package for retrying async throwing work with a compact fluent API.

## Current Scope

Version `0.1.0` ships one public type:

```swift
Retry { ... }
```

Available behavior:

- `.maxAttempts(_:)` to set the number of attempts; values below `1` are clamped to `1`
- `.run()` to execute the operation
- immediate retries only
- cancellation is terminal and is not retried

## Platform Support

- iOS 17 minimum
- macOS 14 minimum

## Example

```swift
let value = try await Retry {
    try await fetchProfile()
}
.maxAttempts(3)
.run()
```

## Coming Next

Planned follow-up releases will add delay, backoff, and jitter policies. Those are not part of `0.1.0`.
