// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "PermissionPilot",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "PermissionPilot", targets: ["PermissionPilotApp"])
  ],
  targets: [
    .executableTarget(
      name: "PermissionPilotApp"
    ),
    .testTarget(
      name: "PermissionPilotTests",
      dependencies: ["PermissionPilotApp"]
    )
  ]
)

