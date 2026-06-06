import XCTest
@testable import PermissionPilotApp

final class TCCDatabaseScannerTests: XCTestCase {
  func testParsesSQLiteTabOutputIntoRecords() {
    let scanner = TCCDatabaseScanner()
    let text = """
    kTCCServiceScreenCapture\tcom.example.App\t0\t2
    kTCCServiceCamera\t/Applications/Camera.app\t1\t0
    """

    let records = scanner.parseRecords(text)

    XCTAssertEqual(records.count, 2)
    XCTAssertEqual(records[0].service, "kTCCServiceScreenCapture")
    XCTAssertEqual(records[0].client, "com.example.App")
    XCTAssertEqual(records[0].clientType, 0)
    XCTAssertEqual(records[0].status, .granted)
    XCTAssertEqual(records[0].authorizationColumn, .unknown)
    XCTAssertEqual(records[1].status, .denied)
  }

  func testParsesAuthorizationColumnMetadata() {
    let scanner = TCCDatabaseScanner()
    let records = scanner.parseRecords(
      "kTCCServiceScreenCapture\tcom.example.App\t0\t2\tUNUSED",
      authorizationColumn: .authValue
    )

    XCTAssertEqual(records[0].authorizationColumn, .authValue)
    XCTAssertEqual(records[0].indirectObjectIdentifier, "UNUSED")
  }

  func testAuthValueOneIsMatchedUnknownNotGranted() {
    let record = TCCAuthorizationRecord(
      service: "kTCCServiceScreenCapture",
      client: "com.example.App",
      clientType: 0,
      authorizationValue: 1,
      authorizationColumn: .authValue
    )

    XCTAssertEqual(record.status, .unknown)
  }

  func testLegacyAllowedOneIsGranted() {
    let record = TCCAuthorizationRecord(
      service: "kTCCServiceScreenCapture",
      client: "com.example.App",
      clientType: 0,
      authorizationValue: 1,
      authorizationColumn: .allowed
    )

    XCTAssertEqual(record.status, .granted)
  }

  func testMapsMatchedBundleRecordToPermissionGrant() {
    let permission = PermissionCatalog.all.first { $0.id == "screen-recording" }!
    let scan = TCCScanResult(
      records: [
        TCCAuthorizationRecord(
          service: "kTCCServiceScreenCapture",
          client: "com.example.App",
          clientType: 0,
          authorizationValue: 2
        )
      ],
      evidence: "Read test database."
    )

    let grant = scan.grant(
      for: permission,
      bundleIdentifier: "com.example.App",
      appPath: "/Applications/Example.app"
    )

    XCTAssertEqual(grant.status, .granted)
    XCTAssertEqual(grant.evidenceKind, .matchedGranted)
    XCTAssertTrue(grant.evidence.contains("kTCCServiceScreenCapture"))
  }

  func testMapsDeniedRecordToTypedEvidence() {
    let permission = PermissionCatalog.all.first { $0.id == "camera" }!
    let scan = TCCScanResult(
      records: [
        TCCAuthorizationRecord(
          service: "kTCCServiceCamera",
          client: "com.example.App",
          clientType: 0,
          authorizationValue: 0,
          authorizationColumn: .allowed
        )
      ],
      evidence: "Read test database.",
      evidenceKind: .databaseRead,
      authorizationColumn: .allowed
    )

    let grant = scan.grant(
      for: permission,
      bundleIdentifier: "com.example.App",
      appPath: "/Applications/Example.app"
    )

    XCTAssertEqual(grant.status, .denied)
    XCTAssertEqual(grant.evidenceKind, .matchedDenied)
    XCTAssertEqual(grant.authorizationColumn, .allowed)
  }

  func testFallsBackToNotRecordedWithoutMatchingRecord() {
    let permission = PermissionCatalog.all.first { $0.id == "camera" }!
    let scan = TCCScanResult(
      records: [
        TCCAuthorizationRecord(
          service: "kTCCServiceMicrophone",
          client: "com.example.App",
          clientType: 0,
          authorizationValue: 2
        )
      ],
      evidence: "Read test database."
    )

    let grant = scan.grant(
      for: permission,
      bundleIdentifier: "com.example.App",
      appPath: "/Applications/Example.app"
    )

    XCTAssertEqual(grant.status, .notRecorded)
    XCTAssertEqual(grant.evidenceKind, .noRecordFound)
    XCTAssertTrue(grant.evidence.contains("does not contain a matching record"))
  }

  func testDatabaseUnavailableEvidenceRemainsUnavailable() {
    let permission = PermissionCatalog.all.first { $0.id == "microphone" }!
    let scan = TCCScanResult(
      records: [],
      evidence: "User TCC database was not readable.",
      evidenceKind: .databaseUnreadable,
      authorizationColumn: .unavailable
    )

    let grant = scan.grant(
      for: permission,
      bundleIdentifier: "com.example.App",
      appPath: "/Applications/Example.app"
    )

    XCTAssertEqual(grant.status, .unavailable)
    XCTAssertEqual(grant.evidenceKind, .databaseUnreadable)
    XCTAssertTrue(grant.evidenceKind.isDatabaseUnavailable)
  }

  func testAppleEventsEvidenceIncludesAutomationTarget() {
    let permission = PermissionCatalog.all.first { $0.id == "automation" }!
    let scan = TCCScanResult(
      records: [
        TCCAuthorizationRecord(
          service: "kTCCServiceAppleEvents",
          client: "com.example.Source",
          clientType: 0,
          authorizationValue: 2,
          indirectObjectIdentifier: "com.apple.finder",
          authorizationColumn: .authValue
        )
      ],
      evidence: "Read test database.",
      evidenceKind: .databaseRead,
      authorizationColumn: .authValue
    )

    let grant = scan.grant(
      for: permission,
      bundleIdentifier: "com.example.Source",
      appPath: "/Applications/Source.app"
    )

    XCTAssertEqual(grant.status, .granted)
    XCTAssertTrue(grant.evidence.contains("Targets: com.apple.finder"))
  }

  func testPathClientMatchingRequiresExactAppPath() {
    let record = TCCAuthorizationRecord(
      service: "kTCCServiceCamera",
      client: "/Applications/App.app",
      clientType: 1,
      authorizationValue: 2
    )

    XCTAssertTrue(record.matches(bundleIdentifier: nil, appPath: "/Applications/App.app"))
    XCTAssertFalse(record.matches(bundleIdentifier: nil, appPath: "/Applications/App.app.localized"))
  }

  func testRecognizesAllRequestedEvidenceKinds() {
    let kinds: [TCCEvidenceKind] = [
      .databaseUnreadable,
      .databaseMissing,
      .noRecordFound,
      .matchedGranted,
      .matchedDenied,
      .serviceUnmapped,
      .queryFailed
    ]

    XCTAssertEqual(kinds.map(\.title).count, 7)
    XCTAssertTrue(TCCEvidenceKind.databaseMissing.isDatabaseUnavailable)
    XCTAssertTrue(TCCEvidenceKind.queryFailed.isDatabaseUnavailable)
  }
}
