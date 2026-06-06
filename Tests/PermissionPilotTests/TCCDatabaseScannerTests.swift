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

  func testNewTCCBackedPermissionsMapToExpectedServices() {
    let expectedServicesByPermissionID: [String: Set<String>] = [
      "photos": ["kTCCServicePhotos", "kTCCServicePhotosAdd"],
      "system-audio-recording": ["kTCCServiceAudioCapture"],
      "files-and-folders": [
        "kTCCServiceSystemPolicyDesktopFolder",
        "kTCCServiceSystemPolicyDocumentsFolder",
        "kTCCServiceSystemPolicyDownloadsFolder",
        "kTCCServiceSystemPolicyNetworkVolumes",
        "kTCCServiceSystemPolicyRemovableVolumes"
      ],
      "calendars": ["kTCCServiceCalendar", "kTCCServiceCalendarFullAccess", "kTCCServiceCalendarWriteOnly"],
      "contacts": ["kTCCServiceAddressBook"],
      "reminders": ["kTCCServiceReminders"],
      "bluetooth": ["kTCCServiceBluetoothAlways", "kTCCServiceBluetoothPeripheral"],
      "local-network": ["kTCCServiceLocalNetwork"],
      "speech-recognition": ["kTCCServiceSpeechRecognition"],
      "keyboard-monitoring": ["kTCCServiceListenEvent"],
      "app-management": ["kTCCServiceSystemPolicyAppBundles"],
      "developer-tools": ["kTCCServiceDeveloperTool"],
      "remote-desktop": ["kTCCServiceRemoteDesktop"],
      "motion-fitness": ["kTCCServiceMotion"],
      "home": ["kTCCServiceWillow"],
      "focus": ["kTCCServiceFocusStatus"],
      "browser-passkey-access": ["kTCCServiceWebBrowserPublicKeyCredential"],
      "media-library": ["kTCCServiceMediaLibrary"]
    ]

    for (permissionID, services) in expectedServicesByPermissionID {
      XCTAssertEqual(TCCServiceMap.servicesByPermissionID[permissionID], services, permissionID)
      XCTAssertNotNil(PermissionCatalog.all.first { $0.id == permissionID }, permissionID)
    }
  }

  func testNewMappedPermissionCanMatchAnyMappedService() {
    let permission = PermissionCatalog.all.first { $0.id == "files-and-folders" }!
    let scan = TCCScanResult(
      records: [
        TCCAuthorizationRecord(
          service: "kTCCServiceSystemPolicyDocumentsFolder",
          client: "com.example.Editor",
          clientType: 0,
          authorizationValue: 2,
          authorizationColumn: .authValue
        )
      ],
      evidence: "Read test database.",
      evidenceKind: .databaseRead,
      authorizationColumn: .authValue
    )

    let grant = scan.grant(
      for: permission,
      bundleIdentifier: "com.example.Editor",
      appPath: "/Applications/Editor.app"
    )

    XCTAssertEqual(grant.status, .granted)
    XCTAssertEqual(grant.evidenceKind, .matchedGranted)
    XCTAssertTrue(grant.evidence.contains("kTCCServiceSystemPolicyDocumentsFolder"))
  }

  func testSystemSettingPermissionsAreNotTCCMapped() {
    let systemSettingIDs = [
      "sensitive-content-warning",
      "blocked-contacts",
      "analytics-improvements",
      "apple-advertising",
      "apple-intelligence-report",
      "filevault",
      "background-security-improvements",
      "blocked-system-software",
      "system-wide-settings-password"
    ]

    for permissionID in systemSettingIDs {
      let permission = PermissionCatalog.all.first { $0.id == permissionID }
      XCTAssertEqual(permission?.evidenceSource, .systemSetting, permissionID)
      XCTAssertNil(TCCServiceMap.servicesByPermissionID[permissionID], permissionID)
    }
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

  func testScanResultPreservesReadableDatabaseMetadataForNoRecordState() {
    let permission = PermissionCatalog.all.first { $0.id == "camera" }!
    let scan = TCCScanResult(
      records: [],
      evidence: "Read user and system TCC databases.",
      evidenceKind: .databaseRead,
      authorizationColumn: .authValue,
      readableDatabaseCount: 2,
      scannedDatabaseCount: 2
    )

    let grant = scan.grant(
      for: permission,
      bundleIdentifier: "com.example.App",
      appPath: "/Applications/Example.app"
    )

    XCTAssertEqual(grant.status, .notRecorded)
    XCTAssertEqual(grant.evidenceKind, .databaseRead)
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
