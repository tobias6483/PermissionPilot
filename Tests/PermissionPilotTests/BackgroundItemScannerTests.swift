import XCTest
@testable import PermissionPilotApp

final class BackgroundItemScannerTests: XCTestCase {
  func testScansPrivilegedHelperToolsAndFlagsUnreferencedExecutables() throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

    let referenced = temporaryDirectory.appendingPathComponent("com.example.referenced")
    let unreferenced = temporaryDirectory.appendingPathComponent("com.example.unreferenced")
    try Data().write(to: referenced)
    try Data().write(to: unreferenced)

    let scanner = BackgroundItemScanner(privilegedHelperToolDirectories: [temporaryDirectory])
    let items = scanner.scanPrivilegedHelperTools(referencedExecutables: [referenced.path])

    XCTAssertEqual(items.count, 2)
    XCTAssertFalse(items.first { $0.label == referenced.lastPathComponent }!.isPotentiallyStale)
    let staleItem = items.first { $0.label == unreferenced.lastPathComponent }!
    XCTAssertTrue(staleItem.isPotentiallyStale)
    XCTAssertTrue(staleItem.staleReason?.contains("not referenced") == true)
    XCTAssertTrue(staleItem.evidence?.contains("privileged helper") == true)
  }

  func testParsesLoginItemsAndBackgroundTasksFromSFLToolDump() {
    let scanner = BackgroundItemScanner()
    let text = """
    ========================
     Records for UID 501 : EXAMPLE
    ========================

     Items:

     #1:
                     UUID: 11111111-1111-1111-1111-111111111111
                     Name: DockerHelper
                     Type: login item (0x4)
              Disposition: [enabled, allowed, notified] (0xb)
               Identifier: 4.com.docker.helper
                      URL: Contents/Library/LoginItems/DockerHelper.app
        Bundle Identifier: com.docker.helper
        Parent Identifier: 2.com.docker.docker

     #2:
                     UUID: 22222222-2222-2222-2222-222222222222
                     Name: ChatGPT - background tasks
                     Type: background tasks (0x2000)
              Disposition: [enabled, allowed, notified] (0xb)
               Identifier: 8192.com.openai.chat
                      URL: (null)
               Generation: 1
        Parent Identifier: 2.com.openai.chat

     #3:
                     UUID: 33333333-3333-3333-3333-333333333333
                     Name: Developer Group
                     Type: developer (0x20)
              Disposition: [disabled, allowed, notified] (0xa)
               Identifier: Developer Group
                      URL: (null)
    """

    let items = scanner.parseSFLToolDumpBTM(text)

    XCTAssertEqual(items.count, 2)
    XCTAssertEqual(items[0].kind, .loginItem)
    XCTAssertEqual(items[0].label, "DockerHelper")
    XCTAssertEqual(items[1].kind, .backgroundTask)
    XCTAssertEqual(items[1].label, "ChatGPT - background tasks")
  }

  func testParsesLegacyAgentPathFromSFLToolDump() {
    let scanner = BackgroundItemScanner()
    let text = """
     #1:
                     UUID: 44444444-4444-4444-4444-444444444444
                     Name: Loopback
                     Type: legacy agent (0x10008)
              Disposition: [enabled, allowed, notified] (0xb)
               Identifier: 8.com.rogueamoeba.loopbackd
                      URL: file:///Users/example/Library/LaunchAgents/com.rogueamoeba.loopbackd.plist
          Executable Path: /Users/example/Library/Application Support/Loopback/Loopback.app/Contents/MacOS/Loopback
    """

    let items = scanner.parseSFLToolDumpBTM(text)

    XCTAssertEqual(items.count, 1)
    XCTAssertEqual(items[0].kind, .launchAgent)
    XCTAssertEqual(items[0].path, "/Users/example/Library/LaunchAgents/com.rogueamoeba.loopbackd.plist")
    XCTAssertEqual(items[0].executable, "/Users/example/Library/Application Support/Loopback/Loopback.app/Contents/MacOS/Loopback")
    XCTAssertTrue(items[0].evidence?.contains("sfltool") == true)
  }

  func testBackgroundItemListFilterCombinesSearchKindAndStaleOnly() {
    let items = [
      makeItem(label: "Alpha Agent", kind: .launchAgent, path: "/Library/LaunchAgents/com.example.alpha.plist", isPotentiallyStale: false),
      makeItem(label: "Beta Helper", kind: .privilegedHelperTool, path: "/Library/PrivilegedHelperTools/com.example.beta", isPotentiallyStale: true),
      makeItem(label: "Gamma Helper", kind: .privilegedHelperTool, path: "/Library/PrivilegedHelperTools/com.example.gamma", isPotentiallyStale: false)
    ]

    let filter = BackgroundItemListFilter(
      searchText: "helper",
      kind: .privilegedHelperTool,
      staleOnly: true,
      sortOrder: .label
    )

    XCTAssertEqual(filter.apply(to: items).map(\.label), ["Beta Helper"])
  }

  func testBackgroundItemListFilterSortsStaleItemsFirst() {
    let items = [
      makeItem(label: "Alpha", isPotentiallyStale: false),
      makeItem(label: "Beta", isPotentiallyStale: true),
      makeItem(label: "Gamma", isPotentiallyStale: true)
    ]

    let filter = BackgroundItemListFilter(sortOrder: .stale)

    XCTAssertEqual(filter.apply(to: items).map(\.label), ["Beta", "Gamma", "Alpha"])
  }

  private func makeItem(
    label: String,
    kind: BackgroundItemKind = .launchAgent,
    path: String? = nil,
    executable: String? = nil,
    isPotentiallyStale: Bool
  ) -> BackgroundItem {
    BackgroundItem(
      id: label,
      kind: kind,
      label: label,
      path: path ?? "/Library/LaunchAgents/\(label).plist",
      executable: executable,
      isPotentiallyStale: isPotentiallyStale
    )
  }
}
