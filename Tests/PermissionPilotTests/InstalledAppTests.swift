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

  func testAppListFilterCombinesPermissionStatusSignatureSearchAndSort() {
    let screenRecording = PermissionCatalog.all[0]
    let microphone = PermissionCatalog.all[3]
    let signed = CodeSignatureInfo(
      isSigned: true,
      teamIdentifier: "TEAMID",
      authorities: ["Developer ID Application"],
      identifier: "com.example.signed",
      evidence: "Signed."
    )

    let apps = [
      makeApp(
        name: "Beta Recorder",
        bundleIdentifier: "com.example.beta",
        path: "/Applications/Beta Recorder.app",
        signingInfo: signed,
        grants: [
          PermissionGrant(permission: screenRecording, status: .granted, evidence: "Matched."),
          PermissionGrant(permission: microphone, status: .unknown, evidence: "No record.")
        ]
      ),
      makeApp(
        name: "Alpha Camera",
        bundleIdentifier: "com.example.alpha",
        path: "/Applications/Alpha Camera.app",
        signingInfo: .unknown,
        grants: [
          PermissionGrant(permission: screenRecording, status: .denied, evidence: "Matched."),
          PermissionGrant(permission: microphone, status: .granted, evidence: "Matched.")
        ]
      ),
      makeApp(
        name: "Gamma Notes",
        bundleIdentifier: "com.example.gamma",
        path: "/Applications/Gamma Notes.app",
        signingInfo: signed,
        grants: [
          PermissionGrant(permission: screenRecording, status: .unknown, evidence: "No record."),
          PermissionGrant(permission: microphone, status: .unknown, evidence: "No record.")
        ]
      )
    ]

    let filter = AppListFilter(
      searchText: "example",
      permission: screenRecording,
      permissionStatus: .granted,
      signature: .signed,
      sortOrder: .name
    )

    XCTAssertEqual(filter.apply(to: apps).map(\.name), ["Beta Recorder"])
  }

  func testAppListFilterSortsBySelectedPermissionStatus() {
    let permission = PermissionCatalog.all[0]
    let apps = [
      makeApp(name: "Unknown", grants: [PermissionGrant(permission: permission, status: .unknown, evidence: "No record.")]),
      makeApp(name: "Granted", grants: [PermissionGrant(permission: permission, status: .granted, evidence: "Matched.")]),
      makeApp(name: "Denied", grants: [PermissionGrant(permission: permission, status: .denied, evidence: "Matched.")])
    ]

    let filter = AppListFilter(permission: permission, sortOrder: .permissionStatus)

    XCTAssertEqual(filter.apply(to: apps).map(\.name), ["Granted", "Denied", "Unknown"])
  }

  func testPermissionStatusSummaryCountsSelectedPermissionStates() {
    let screenRecording = PermissionCatalog.all[0]
    let microphone = PermissionCatalog.all[3]
    let apps = [
      makeApp(
        name: "Granted",
        grants: [
          PermissionGrant(permission: screenRecording, status: .granted, evidence: "Matched."),
          PermissionGrant(permission: microphone, status: .unknown, evidence: "No record.")
        ]
      ),
      makeApp(
        name: "Denied",
        grants: [PermissionGrant(permission: screenRecording, status: .denied, evidence: "Matched.")]
      ),
      makeApp(
        name: "Unknown",
        grants: [PermissionGrant(permission: screenRecording, status: .unknown, evidence: "No record.")]
      ),
      makeApp(
        name: "Missing",
        grants: []
      )
    ]

    let summary = PermissionStatusSummary(permission: screenRecording, apps: apps)

    XCTAssertEqual(summary.granted, 1)
    XCTAssertEqual(summary.denied, 1)
    XCTAssertEqual(summary.unknown, 2)
    XCTAssertEqual(summary.total, 4)
    XCTAssertTrue(summary.hasKnownState)
  }

  func testReviewPriorityIsHighForUnsignedHighSensitivityGrant() {
    let app = makeApp(
      name: "Recorder",
      signingInfo: .unknown,
      grants: [
        PermissionGrant(permission: PermissionCatalog.all[0], status: .granted, evidence: "Matched.", evidenceKind: .matchedGranted)
      ]
    )

    let assessment = app.reviewPriorityAssessment

    XCTAssertEqual(assessment.priority, .high)
    XCTAssertTrue(assessment.reasons.contains { $0.contains("Screen Recording") })
    XCTAssertFalse(assessment.reasons.joined(separator: " ").localizedCaseInsensitiveContains("malware"))
  }

  func testReviewPriorityIsMediumForUnsignedWithoutSensitiveGrants() {
    let app = makeApp(
      name: "Unsigned",
      signingInfo: .unknown,
      grants: [
        PermissionGrant(permission: PermissionCatalog.all[0], status: .unknown, evidence: "No record.", evidenceKind: .noRecordFound)
      ]
    )

    XCTAssertEqual(app.reviewPriorityAssessment.priority, .medium)
  }

  func testReviewPriorityIsLowWithoutSignals() {
    let signed = CodeSignatureInfo(
      isSigned: true,
      teamIdentifier: "TEAMID",
      authorities: ["Developer ID Application"],
      identifier: "com.example.signed",
      evidence: "Signed."
    )
    let app = makeApp(
      name: "Signed",
      signingInfo: signed,
      grants: [
        PermissionGrant(permission: PermissionCatalog.all[0], status: .unknown, evidence: "No record.", evidenceKind: .noRecordFound)
      ]
    )

    XCTAssertEqual(app.reviewPriorityAssessment.priority, .low)
  }

  func testGuidanceDetectsDatabaseUnreadableAndEmptyStates() {
    let app = makeApp(
      name: "Unreadable",
      grants: [
        PermissionGrant(permission: PermissionCatalog.all[0], status: .unknown, evidence: "Unreadable.", evidenceKind: .databaseUnreadable)
      ]
    )

    XCTAssertEqual(DashboardGuidanceEvaluator.guidance(apps: [app], backgroundItems: []), [.databaseUnreadable, .noBackgroundItemsFound])
    XCTAssertEqual(DashboardGuidanceEvaluator.guidance(apps: [], backgroundItems: []), [.noAppsFound, .noBackgroundItemsFound])
  }

  private func makeApp(
    name: String,
    bundleIdentifier: String? = nil,
    path: String? = nil,
    signingInfo: CodeSignatureInfo = .unknown,
    grants: [PermissionGrant]
  ) -> InstalledApp {
    InstalledApp(
      id: bundleIdentifier ?? name,
      name: name,
      bundleIdentifier: bundleIdentifier,
      path: path ?? "/Applications/\(name).app",
      signingInfo: signingInfo,
      permissions: grants
    )
  }
}
