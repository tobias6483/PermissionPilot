import XCTest
@testable import PermissionPilotApp

final class InstalledAppTests: XCTestCase {
  func testHighestSensitivityIgnoresUnknownPermissions() {
    let app = InstalledApp(
      id: "example",
      name: "Example",
      bundleIdentifier: "com.example.App",
      path: "/Applications/Example.app",
      permissions: [
        PermissionGrant(permission: PermissionCatalog.all[0], status: .unknown, evidence: "No record."),
        PermissionGrant(permission: PermissionCatalog.all[3], status: .granted, evidence: "Matched record.")
      ]
    )

    XCTAssertEqual(app.highestSensitivity, .medium)
  }
}

