// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let package = Package(
    name: "Libipf",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Libipf",
            targets: ["Libipf"]),
    ],
    targets: [
        .target(
            name: "Libipf",
            dependencies: ["Ipf"]),
        .binaryTarget(
            name: "Ipf",
            path: "Ipf.xcframework"),
    ]
)
