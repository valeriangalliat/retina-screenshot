// swift-tools-version: 5.8

import PackageDescription

let package = Package(
  name: "retina-screenshot",
  platforms: [
    .macOS(.v13)
  ],
  dependencies: [
    .package(url: "https://github.com/realm/SwiftLint.git", from: "0.52.1")
  ],
  targets: [
    .executableTarget(
      name: "retina-screenshot",
      path: "Sources",
      resources: [
        .copy("Cursors")
      ],
      plugins: [
        .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
      ]
    )
  ]
)
