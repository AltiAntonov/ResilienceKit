<div align="center">
  <h1>ResilienceKit</h1>
  <p><strong>Small async retry primitives for Swift with explicit attempts and terminal cancellation.</strong></p>
  <p>
    <a href="https://swiftpackageindex.com/AltiAntonov/ResilienceKit">
      <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAltiAntonov%2FResilienceKit%2Fbadge%3Ftype%3Dswift-versions" alt="Swift version compatibility">
    </a>
    <a href="https://swiftpackageindex.com/AltiAntonov/ResilienceKit">
      <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAltiAntonov%2FResilienceKit%2Fbadge%3Ftype%3Dplatforms" alt="Platform compatibility">
    </a>
    <img src="https://img.shields.io/badge/License-MIT-34C759" alt="MIT License">
    <a href="https://github.com/AltiAntonov/ResilienceKit/actions/workflows/swift.yml"><img src="https://github.com/AltiAntonov/ResilienceKit/actions/workflows/swift.yml/badge.svg" alt="Swift workflow"></a>
  </p>
  <p>
    <a href="#features">Features</a> ·
    <a href="#installation">Installation</a> ·
    <a href="#quick-start">Quick Start</a> ·
    <a href="#when-to-use">When To Use</a> ·
    <a href="#good-fits">Good Fits</a> ·
    <a href="#weaker-fits">Weaker Fits</a> ·
    <a href="#runtime-semantics">Runtime Semantics</a> ·
    <a href="#documentation">Documentation</a> ·
    <a href="#testing">Testing</a>
  </p>
</div>

## Features

- async-first retry entry point with `Retry { ... }`
- explicit `.maxAttempts(_:)` configuration
- fixed delay support through `.delay(_:)`
- terminal cancellation that is not retried
- small surface area intended to grow in layers

The current public API is intentionally centered on:

- `Retry`

## Installation

Add `ResilienceKit` to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/AltiAntonov/ResilienceKit.git", from: "0.2.1")
]
```

Then add the product to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "ResilienceKit", package: "ResilienceKit")
    ]
)
```

## Quick Start

```swift
import ResilienceKit

let value = try await Retry {
    try await fetchProfile()
}
.maxAttempts(3)
.delay(.seconds(1))
.run()
```

`maxAttempts(_:)` always means total executions, including the first call.

## When To Use

Use `ResilienceKit` when you want retry behavior to be explicit, readable, and reusable instead of re-implementing ad hoc retry loops around async work.

It is a strong fit when the first thing you need is a small retry primitive, not a full resilience framework.

## Good Fits

- app and SDK code that wraps async network requests
- codebases that want one obvious retry call site instead of repeated `for` loops
- teams that want to add backoff and jitter later without changing the entry-point shape
- small packages or apps that want focused retry behavior without unrelated dependencies

## Weaker Fits

- projects that need backoff, jitter, or retry predicates today
- systems that already require a broader resilience stack such as circuit breaking or rate limiting
- sync-only code paths
- packages that need broad platform coverage below iOS 17 or macOS 14 right now

## Runtime Semantics

- `.maxAttempts(_:)` controls the total number of attempts, not retries-after-the-first
- values below `1` are clamped to `1`
- `.delay(_:)` configures a fixed delay between failed attempts and defaults to `.zero`
- the first attempt always starts immediately
- delay is applied only between eligible retries, never after the final failed attempt
- cancellation before the first attempt prevents the operation from running
- `CancellationError` is terminal and is rethrown without additional attempts
- cancellation during delay is rethrown and no later attempt runs
- all non-cancellation thrown errors are retried until attempts are exhausted

Backoff, jitter, and retry predicates are intentionally deferred to later releases.

## Documentation

The package now includes a DocC catalog in `Sources/ResilienceKit/ResilienceKit.docc`.

Once Swift Package Index processes `.spi.yml`, hosted documentation should appear on the package page automatically.

## Testing

The package uses Swift Testing.

Current coverage verifies:

- first-attempt success
- retry-until-success behavior
- fixed delay between failed attempts
- no trailing delay after the final failed attempt
- exact call count on persistent failure
- clamp behavior for invalid attempt counts
- terminal cancellation from both pre-cancelled tasks, thrown `CancellationError`, and cancellation during delay
