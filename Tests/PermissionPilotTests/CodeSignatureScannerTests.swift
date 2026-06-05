import XCTest
@testable import PermissionPilotApp

final class CodeSignatureScannerTests: XCTestCase {
  func testParsesCodesignDetails() {
    let scanner = CodeSignatureScanner()
    let text = """
    Executable=/Applications/Example.app/Contents/MacOS/Example
    Identifier=com.example.app
    TeamIdentifier=ABCDE12345
    Authority=Developer ID Application: Example Corp (ABCDE12345)
    Authority=Developer ID Certification Authority
    Authority=Apple Root CA
    """

    let info = scanner.parseCodesignDetails(text)

    XCTAssertTrue(info.isSigned)
    XCTAssertEqual(info.identifier, "com.example.app")
    XCTAssertEqual(info.teamIdentifier, "ABCDE12345")
    XCTAssertEqual(info.authorities.count, 3)
    XCTAssertTrue(info.evidence.contains("ABCDE12345"))
  }
}

