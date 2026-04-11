# Changelog

All notable changes to `ResilienceKit` will be documented in this file.

## 0.2.0

- Added `.delay(_:)` for fixed delay between failed retry attempts
- Kept the first attempt immediate and skipped trailing delay after the final failure
- Rethrow `CancellationError` if cancellation happens during delay
- Added tests and documentation for delayed retry behavior

## 0.1.1

- Clarified public documentation around total attempts vs retries
- Added public API doc comments for `Retry`, `.maxAttempts(_:)`, and `.run()`
- Simplified retry executor terminal control flow by removing the forced unwrap fallback
- Aligned release notes and planning metadata with the shipped `0.1.0` baseline

## 0.1.0

Initial release.

- Added `Retry { ... }` as the async retry entry point
- Added `.maxAttempts(_:)` for configuring attempt count, with a minimum effective value of `1`
- Added `.run()` for execution
- Retries happen immediately with no delay or backoff
- Cancellation stops execution and is not retried
