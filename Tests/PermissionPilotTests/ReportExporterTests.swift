import Foundation
import XCTest
@testable import PermissionPilotApp

final class ReportExporterTests: XCTestCase {
  func testMarkdownIncludesAppsAndBackgroundItems() {
    let report = PrivacyReport(
      generatedAt: Date(timeIntervalSince1970: 0),
      apps: [
        InstalledApp(
          id: "example",
          name: "Example",
          bundleIdentifier: "com.example.app",
          path: "/Applications/Example.app",
          permissions: [
            PermissionGrant(
              permission: PermissionCatalog.all[0],
              status: .unknown,
              evidence: "No local TCC evidence yet."
            )
          ]
        )
      ],
      backgroundItems: [
        BackgroundItem(
          id: "/Library/LaunchAgents/com.example.agent.plist",
          kind: .launchAgent,
          label: "com.example.agent",
          path: "/Library/LaunchAgents/com.example.agent.plist",
          executable: "/Applications/Example.app/Contents/MacOS/helper",
          isPotentiallyStale: true
        )
      ]
    )

    let markdown = ReportExporter.markdown(report: report)

    XCTAssertTrue(markdown.contains("PermissionPilot Privacy Report"))
    XCTAssertTrue(markdown.contains("Example"))
    XCTAssertTrue(markdown.contains("com.example.agent"))
    XCTAssertTrue(markdown.contains("Potentially stale"))
  }

  func testJSONEncodesReport() throws {
    let report = PrivacyReport(generatedAt: Date(timeIntervalSince1970: 0), apps: [], backgroundItems: [])

    let data = try ReportExporter.json(report: report)
    let text = String(decoding: data, as: UTF8.self)

    XCTAssertTrue(text.contains("\"apps\""))
    XCTAssertTrue(text.contains("\"backgroundItems\""))
  }
}

