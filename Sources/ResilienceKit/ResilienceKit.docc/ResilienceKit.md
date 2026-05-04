# ``ResilienceKit``

Small async retry primitives for Swift with explicit attempts and terminal cancellation.

## Overview

`ResilienceKit` helps Swift apps and libraries apply retry behavior without rebuilding the same async retry loop in every call site.

The current package intentionally keeps the surface area small:

- one public entry point: ``Retry``
- explicit total-attempt configuration through ``Retry/maxAttempts(_:)``
- fixed delay between failed attempts through ``Retry/delay(_:)``
- exponential backoff through ``Retry/exponentialBackoff(baseDelay:multiplier:maxDelay:jitter:)``
- bounded jitter through ``RetryJitter``
- generic retry predicates through ``Retry/retry(_:)``
- terminal cancellation before execution, during delay, or from the operation itself

`ResilienceKit` is a good fit when you want a compact retry primitive with fixed delay, exponential backoff, jitter, and selective retry without pulling in a broader resilience framework.

## Topics

### Essentials

- <doc:GettingStarted>

### Core Types

- ``Retry``
- ``RetryJitter``
