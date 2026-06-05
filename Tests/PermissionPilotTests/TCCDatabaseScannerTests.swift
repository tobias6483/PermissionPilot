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
    XCTAssertEqual(records[1].status, .denied)
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
    XCTAssertTrue(grant.evidence.contains("kTCCServiceScreenCapture"))
  }

  func testFallsBackToUnknownWithoutMatchingRecord() {
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

    XCTAssertEqual(grant.status, .unknown)
    XCTAssertTrue(grant.evidence.contains("No matching TCC record"))
  }
}

