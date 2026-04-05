//
//  Package.swift
//  ResilienceKit
//
//  Declares the Swift package manifest for ResilienceKit.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//
//
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ResilienceKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ResilienceKit",
            targets: ["ResilienceKit"]
        )
    ],
    targets: [
        .target(
            name: "ResilienceKit"
        ),
        .testTarget(
            name: "ResilienceKitTests",
            dependencies: ["ResilienceKit"]
        )
    ]
)
