import Foundation
import XCTest
@testable import PermissionPilotApp

final class ReportExporterTests: XCTestCase {
  func testDefaultFileNamesIncludeScopeFormatAndTimestamp() {
    let generatedAt = Date(timeIntervalSince1970: 1_704_067_200)

    XCTAssertEqual(
      ReportExporter.defaultFileName(scope: .full, format: .markdown, generatedAt: generatedAt),
      "permissionpilot-full-report-20240101-000000.md"
    )
    XCTAssertEqual(
      ReportExporter.defaultFileName(scope: .filtered, format: .json, generatedAt: generatedAt),
      "permissionpilot-filtered-report-20240101-000000.json"
    )
  }

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
              status: .notRecorded,
              evidence: "No local TCC evidence yet.",
              evidenceKind: .noRecordFound
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
          isPotentiallyStale: true,
          staleReason: "Referenced executable was not found.",
          evidence: "Parsed test plist."
        )
      ]
    )

    let markdown = ReportExporter.markdown(report: report)

    XCTAssertTrue(markdown.contains("PermissionPilot Privacy Report"))
    XCTAssertTrue(markdown.contains("Scan Summary"))
    XCTAssertTrue(markdown.contains("Permission Summary"))
    XCTAssertTrue(markdown.contains("Apps scanned: 1"))
    XCTAssertTrue(markdown.contains("Potentially stale background items: 1"))
    XCTAssertTrue(markdown.contains("Example"))
    XCTAssertTrue(markdown.contains("com.example.agent"))
    XCTAssertTrue(markdown.contains("Potentially stale"))
    XCTAssertTrue(markdown.contains("No record found"))
    XCTAssertTrue(markdown.contains("Review priority"))
  }

  func testJSONEncodesReport() throws {
    let report = PrivacyReport(generatedAt: Date(timeIntervalSince1970: 0), apps: [], backgroundItems: [])

    let data = try ReportExporter.json(report: report)
    let text = String(decoding: data, as: UTF8.self)

    XCTAssertTrue(text.contains("\"summary\""))
    XCTAssertTrue(text.contains("\"report\""))
    XCTAssertTrue(text.contains("\"appCount\""))
    XCTAssertTrue(text.contains("\"backgroundItems\""))
    XCTAssertTrue(text.contains("\"scope\""))
  }

  func testFilteredReportExportsScopeAndSummaryForFilteredData() throws {
    let report = PrivacyReport(
      generatedAt: Date(timeIntervalSince1970: 0),
      apps: [
        InstalledApp(
          id: "filtered",
          name: "Filtered",
          bundleIdentifier: "com.example.filtered",
          path: "/Applications/Filtered.app",
          permissions: [
            PermissionGrant(permission: PermissionCatalog.all[0], status: .granted, evidence: "Matched.", evidenceKind: .matchedGranted)
          ]
        )
      ],
      backgroundItems: [],
      scope: .filtered,
      filters: ReportFilterDescription(
        appSearchText: "filtered",
        selectedPermissionID: PermissionCatalog.all[0].id,
        permissionStatus: .granted,
        signature: .any,
        appSortOrder: .reviewPriority,
        backgroundSearchText: "",
        backgroundKind: .any,
        staleOnly: false,
        backgroundSortOrder: .label
      )
    )

    let markdown = ReportExporter.markdown(report: report)
    let json = String(decoding: try ReportExporter.json(report: report), as: UTF8.self)

    XCTAssertTrue(markdown.contains("Filtered Privacy Report"))
    XCTAssertTrue(markdown.contains("Scope: filtered"))
    XCTAssertTrue(json.contains("\"scope\" : \"filtered\""))
    XCTAssertTrue(json.contains("\"appCount\" : 1"))
  }

  func testReportSummaryCountsAppsPermissionsAndBackgroundItems() {
    let highPermission = PermissionCatalog.all[0]
    let mediumPermission = PermissionCatalog.all[3]
    let report = PrivacyReport(
      generatedAt: Date(timeIntervalSince1970: 0),
      apps: [
        InstalledApp(
          id: "signed",
          name: "Signed",
          bundleIdentifier: "com.example.signed",
          path: "/Applications/Signed.app",
          signingInfo: CodeSignatureInfo(
            isSigned: true,
            teamIdentifier: "TEAMID",
            authorities: ["Developer ID Application"],
            identifier: "com.example.signed",
            evidence: "Signed."
          ),
          permissions: [
            PermissionGrant(permission: highPermission, status: .granted, evidence: "Matched."),
            PermissionGrant(permission: mediumPermission, status: .denied, evidence: "Matched.")
          ]
        ),
        InstalledApp(
          id: "unknown",
          name: "Unknown",
          bundleIdentifier: "com.example.unknown",
          path: "/Applications/Unknown.app",
          permissions: [
            PermissionGrant(permission: highPermission, status: .notRecorded, evidence: "No record.")
          ]
        )
      ],
      backgroundItems: [
        BackgroundItem(id: "agent", kind: .launchAgent, label: "Agent", path: "/Library/LaunchAgents/agent.plist", executable: nil, isPotentiallyStale: false),
        BackgroundItem(id: "helper", kind: .privilegedHelperTool, label: "Helper", path: "/Library/PrivilegedHelperTools/helper", executable: nil, isPotentiallyStale: true)
      ]
    )

    let summary = PrivacyReportSummary(report: report)

    XCTAssertEqual(summary.appCount, 2)
    XCTAssertEqual(summary.signedAppCount, 1)
    XCTAssertEqual(summary.unsignedOrUnknownAppCount, 1)
    XCTAssertEqual(summary.highSensitivityGrantCount, 1)
    XCTAssertEqual(summary.backgroundItemCount, 2)
    XCTAssertEqual(summary.potentiallyStaleBackgroundItemCount, 1)
    XCTAssertEqual(summary.backgroundItemKindCounts[.launchAgent], 1)
    XCTAssertEqual(summary.backgroundItemKindCounts[.privilegedHelperTool], 1)
    XCTAssertEqual(summary.permissionSummaries.first { $0.id == highPermission.id }?.granted, 1)
    XCTAssertEqual(summary.permissionSummaries.first { $0.id == highPermission.id }?.unknown, 0)
    XCTAssertEqual(summary.permissionSummaries.first { $0.id == highPermission.id }?.notRecorded, 1)
  }
}
