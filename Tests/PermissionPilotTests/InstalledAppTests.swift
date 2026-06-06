import XCTest
@testable import PermissionPilotApp

final class InstalledAppTests: XCTestCase {
  func testHighestSensitivityIgnoresUnknownPermissions() {
    let screenRecording = PermissionCatalog.all.first { $0.id == "screen-recording" }!
    let microphone = PermissionCatalog.all.first { $0.id == "microphone" }!
    let app = InstalledApp(
      id: "example",
      name: "Example",
      bundleIdentifier: "com.example.App",
      path: "/Applications/Example.app",
      permissions: [
        PermissionGrant(permission: screenRecording, status: .notRecorded, evidence: "No record."),
        PermissionGrant(permission: microphone, status: .granted, evidence: "Matched record.")
      ]
    )

    XCTAssertEqual(app.highestSensitivity, .medium)
  }

  func testAppListFilterCombinesPermissionStatusSignatureSearchAndSort() {
    let screenRecording = PermissionCatalog.all[0]
    let microphone = PermissionCatalog.all.first { $0.id == "microphone" }!
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
          PermissionGrant(permission: microphone, status: .notRecorded, evidence: "No record.")
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
          PermissionGrant(permission: screenRecording, status: .notRecorded, evidence: "No record."),
          PermissionGrant(permission: microphone, status: .notRecorded, evidence: "No record.")
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
      makeApp(name: "Not Recorded", grants: [PermissionGrant(permission: permission, status: .notRecorded, evidence: "No record.")]),
      makeApp(name: "Granted", grants: [PermissionGrant(permission: permission, status: .granted, evidence: "Matched.")]),
      makeApp(name: "Denied", grants: [PermissionGrant(permission: permission, status: .denied, evidence: "Matched.")]),
      makeApp(name: "Unavailable", grants: [PermissionGrant(permission: permission, status: .unavailable, evidence: "Unreadable.", evidenceKind: .databaseUnreadable)]),
      makeApp(name: "Unknown", grants: [PermissionGrant(permission: permission, status: .unknown, evidence: "Matched unknown.", evidenceKind: .matchedUnknown)])
    ]

    let filter = AppListFilter(permission: permission, sortOrder: .permissionStatus)

    XCTAssertEqual(filter.apply(to: apps).map(\.name), ["Granted", "Denied", "Unknown", "Unavailable", "Not Recorded"])
  }

  func testAppListFilterRecordedStatusExcludesNotRecordedApps() {
    let permission = PermissionCatalog.all[0]
    let apps = [
      makeApp(name: "Granted", grants: [PermissionGrant(permission: permission, status: .granted, evidence: "Matched.")]),
      makeApp(name: "Denied", grants: [PermissionGrant(permission: permission, status: .denied, evidence: "Matched.")]),
      makeApp(name: "Unknown", grants: [PermissionGrant(permission: permission, status: .unknown, evidence: "Matched unknown.", evidenceKind: .matchedUnknown)]),
      makeApp(name: "Unavailable", grants: [PermissionGrant(permission: permission, status: .unavailable, evidence: "Unreadable.", evidenceKind: .databaseUnreadable)]),
      makeApp(name: "Not Recorded", grants: [PermissionGrant(permission: permission, status: .notRecorded, evidence: "No record.")]),
      makeApp(name: "Missing Grant", grants: [])
    ]

    let filter = AppListFilter(
      permission: permission,
      permissionStatus: .recorded,
      sortOrder: .permissionStatus
    )

    XCTAssertEqual(filter.apply(to: apps).map(\.name), ["Granted", "Denied", "Unknown", "Unavailable"])
  }

  func testAppListFilterAnyStatusIncludesMissingPermissionAsNotRecorded() {
    let permission = PermissionCatalog.all[0]
    let apps = [
      makeApp(name: "Granted", grants: [PermissionGrant(permission: permission, status: .granted, evidence: "Matched.")]),
      makeApp(name: "Missing Grant", grants: [])
    ]

    let filter = AppListFilter(permission: permission, permissionStatus: .any)

    XCTAssertEqual(filter.apply(to: apps).map(\.name), ["Granted", "Missing Grant"])
  }

  func testPermissionStatusSummaryCountsSelectedPermissionStates() {
    let screenRecording = PermissionCatalog.all[0]
    let microphone = PermissionCatalog.all.first { $0.id == "microphone" }!
    let apps = [
      makeApp(
        name: "Granted",
        grants: [
          PermissionGrant(permission: screenRecording, status: .granted, evidence: "Matched."),
          PermissionGrant(permission: microphone, status: .notRecorded, evidence: "No record.")
        ]
      ),
      makeApp(
        name: "Denied",
        grants: [PermissionGrant(permission: screenRecording, status: .denied, evidence: "Matched.")]
      ),
      makeApp(
        name: "Unknown",
        grants: [PermissionGrant(permission: screenRecording, status: .unknown, evidence: "Matched unknown.", evidenceKind: .matchedUnknown)]
      ),
      makeApp(
        name: "Missing",
        grants: []
      )
    ]

    let summary = PermissionStatusSummary(permission: screenRecording, apps: apps)

    XCTAssertEqual(summary.granted, 1)
    XCTAssertEqual(summary.denied, 1)
    XCTAssertEqual(summary.unknown, 1)
    XCTAssertEqual(summary.notRecorded, 1)
    XCTAssertEqual(summary.unavailable, 0)
    XCTAssertEqual(summary.total, 4)
    XCTAssertTrue(summary.hasKnownState)
  }

  func testPermissionStatusSummaryDefaultsToGrantedWhenGrantedAppsExist() {
    let permission = PermissionCatalog.all[0]
    let apps = [
      makeApp(name: "Denied", grants: [PermissionGrant(permission: permission, status: .denied, evidence: "Matched.")]),
      makeApp(name: "Granted", grants: [PermissionGrant(permission: permission, status: .granted, evidence: "Matched.")])
    ]

    let summary = PermissionStatusSummary(permission: permission, apps: apps)

    XCTAssertEqual(summary.defaultStatusFilter, .granted)
  }

  func testPermissionStatusSummaryDefaultsToDeniedWhenOnlyDeniedAppsExist() {
    let permission = PermissionCatalog.all[0]
    let apps = [
      makeApp(name: "Denied", grants: [PermissionGrant(permission: permission, status: .denied, evidence: "Matched.")]),
      makeApp(name: "Not Recorded", grants: [PermissionGrant(permission: permission, status: .notRecorded, evidence: "No record.")])
    ]

    let summary = PermissionStatusSummary(permission: permission, apps: apps)

    XCTAssertEqual(summary.defaultStatusFilter, .denied)
  }

  func testPermissionStatusSummaryDefaultsToRecordedWithoutGrantedOrDeniedApps() {
    let permission = PermissionCatalog.all[0]
    let apps = [
      makeApp(name: "Unknown", grants: [PermissionGrant(permission: permission, status: .unknown, evidence: "Matched unknown.", evidenceKind: .matchedUnknown)]),
      makeApp(name: "Not Recorded", grants: [PermissionGrant(permission: permission, status: .notRecorded, evidence: "No record.")])
    ]

    let summary = PermissionStatusSummary(permission: permission, apps: apps)

    XCTAssertEqual(summary.defaultStatusFilter, .recorded)
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
        PermissionGrant(permission: PermissionCatalog.all[0], status: .notRecorded, evidence: "No record.", evidenceKind: .noRecordFound)
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
        PermissionGrant(permission: PermissionCatalog.all[0], status: .notRecorded, evidence: "No record.", evidenceKind: .noRecordFound)
      ]
    )

    XCTAssertEqual(app.reviewPriorityAssessment.priority, .low)
  }

  func testGuidanceDetectsDatabaseUnreadableAndEmptyStates() {
    let app = makeApp(
      name: "Unreadable",
      grants: [
        PermissionGrant(permission: PermissionCatalog.all[0], status: .unavailable, evidence: "Unreadable.", evidenceKind: .databaseUnreadable)
      ]
    )

    XCTAssertEqual(DashboardGuidanceEvaluator.guidance(apps: [app], backgroundItems: []), [.databaseUnreadable, .noBackgroundItemsFound])
    XCTAssertEqual(DashboardGuidanceEvaluator.guidance(apps: [], backgroundItems: []), [.noAppsFound, .noBackgroundItemsFound])
  }

  func testGuidanceDoesNotTreatNotRecordedAsUnknownWarning() {
    let app = makeApp(
      name: "No Records",
      grants: [
        PermissionGrant(permission: PermissionCatalog.all[0], status: .notRecorded, evidence: "No record.", evidenceKind: .noRecordFound)
      ]
    )

    XCTAssertEqual(DashboardGuidanceEvaluator.guidance(apps: [app], backgroundItems: [BackgroundItem(id: "agent", kind: .launchAgent, label: "Agent", path: "/Library/LaunchAgents/agent.plist", executable: nil, isPotentiallyStale: false)]), [])
  }

  func testSystemPrivacySettingsScannerMarksGlobalSettingsAsNotAppScoped() {
    let permission = PermissionCatalog.all.first { $0.id == "analytics-improvements" }!
    let grant = SystemPrivacySettingsScanner().grant(for: permission)

    XCTAssertEqual(grant.status, .unavailable)
    XCTAssertEqual(grant.evidenceKind, .systemSettingNotAppScoped)
    XCTAssertEqual(grant.authorizationColumn, .unavailable)
    XCTAssertTrue(grant.evidence.contains("not exposed as a per-app TCC grant"))
  }

  func testSystemSettingSummariesDoNotCountAppsAsUnavailable() {
    let permission = PermissionCatalog.all.first { $0.id == "filevault" }!
    let apps = [
      makeApp(name: "One", grants: []),
      makeApp(name: "Two", grants: [])
    ]

    let summary = PermissionStatusSummary(permission: permission, apps: apps)

    XCTAssertEqual(summary.total, 0)
    XCTAssertEqual(summary.unavailable, 0)
    XCTAssertEqual(summary.notRecorded, 0)
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
