# Changelog

All notable changes to `ResilienceKit` will be documented in this file.

## 0.1.0

Initial release.

- Added `Retry { ... }` as the async retry entry point
- Added `.maxAttempts(_:)` for configuring attempt count, with a minimum effective value of `1`
- Added `.run()` for execution
- Retries happen immediately with no delay or backoff
- Cancellation stops execution and is not retried
