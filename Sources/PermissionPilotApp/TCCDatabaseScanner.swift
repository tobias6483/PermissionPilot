import Foundation

protocol TCCDatabaseScanning {
  func scan() -> TCCScanResult
}

struct TCCScanResult {
  let records: [TCCAuthorizationRecord]
  let evidence: String

  func grant(for permission: PermissionDefinition, bundleIdentifier: String?, appPath: String) -> PermissionGrant {
    guard let services = TCCServiceMap.servicesByPermissionID[permission.id] else {
      return PermissionGrant(permission: permission, status: .unknown, evidence: "No TCC service mapping exists for this permission yet.")
    }

    guard !records.isEmpty else {
      return PermissionGrant(permission: permission, status: .unknown, evidence: evidence)
    }

    let matched = records.filter { record in
      services.contains(record.service) && record.matches(bundleIdentifier: bundleIdentifier, appPath: appPath)
    }

    guard !matched.isEmpty else {
      return PermissionGrant(permission: permission, status: .unknown, evidence: "No matching TCC record was found for this app.")
    }

    let status = matched.contains { $0.status == .granted } ? PermissionStatus.granted : matched[0].status
    let serviceList = matched.map(\.service).uniqued().joined(separator: ", ")
    return PermissionGrant(permission: permission, status: status, evidence: "Matched TCC service record: \(serviceList).")
  }
}

struct TCCAuthorizationRecord: Hashable {
  let service: String
  let client: String
  let clientType: Int?
  let authorizationValue: Int?

  var status: PermissionStatus {
    switch authorizationValue {
    case 1, 2:
      return .granted
    case 0:
      return .denied
    default:
      return .unknown
    }
  }

  func matches(bundleIdentifier: String?, appPath: String) -> Bool {
    if clientType == 0, let bundleIdentifier {
      return client == bundleIdentifier
    }

    if clientType == 1 {
      return client == appPath || appPath.hasPrefix(client)
    }

    return client == bundleIdentifier || client == appPath || appPath.hasPrefix(client)
  }
}

struct TCCDatabaseScanner: TCCDatabaseScanning {
  var databaseURL: URL = FileManager.default
    .homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")

  func scan() -> TCCScanResult {
    guard FileManager.default.fileExists(atPath: databaseURL.path) else {
      return TCCScanResult(records: [], evidence: "User TCC database was not found at the expected path.")
    }

    let columnsResult = runSQLite(arguments: ["-tabs", databaseURL.path, "PRAGMA table_info(access);"])
    guard columnsResult.exitCode == 0 else {
      return TCCScanResult(records: [], evidence: "User TCC database was not readable. Grant Full Disk Access to PermissionPilot to inspect TCC records.")
    }

    let columns = parseTableInfo(columnsResult.output)
    guard columns.contains("service"), columns.contains("client") else {
      return TCCScanResult(records: [], evidence: "TCC access table did not contain expected service/client columns.")
    }

    let valueColumn: String
    if columns.contains("auth_value") {
      valueColumn = "auth_value"
    } else if columns.contains("allowed") {
      valueColumn = "allowed"
    } else {
      valueColumn = "NULL"
    }

    let clientTypeColumn = columns.contains("client_type") ? "client_type" : "NULL"
    let query = "SELECT service, client, \(clientTypeColumn), \(valueColumn) FROM access;"
    let recordsResult = runSQLite(arguments: ["-tabs", databaseURL.path, query])

    guard recordsResult.exitCode == 0 else {
      return TCCScanResult(records: [], evidence: "TCC records could not be queried: \(recordsResult.error.trimmingCharacters(in: .whitespacesAndNewlines))")
    }

    return TCCScanResult(records: parseRecords(recordsResult.output), evidence: "Read user TCC database at \(databaseURL.path).")
  }

  private func parseTableInfo(_ text: String) -> Set<String> {
    Set(text
      .split(separator: "\n")
      .compactMap { line in
        let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
        guard fields.count > 1 else {
          return nil
        }
        return String(fields[1])
      })
  }

  func parseRecords(_ text: String) -> [TCCAuthorizationRecord] {
    text
      .split(separator: "\n")
      .compactMap { line in
        let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
        guard fields.count >= 4 else {
          return nil
        }

        return TCCAuthorizationRecord(
          service: String(fields[0]),
          client: String(fields[1]),
          clientType: Int(fields[2]),
          authorizationValue: Int(fields[3])
        )
      }
  }

  private func runSQLite(arguments: [String]) -> (exitCode: Int32, output: String, error: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
    process.arguments = arguments

    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      return (1, "", error.localizedDescription)
    }

    let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    return (process.terminationStatus, output, error)
  }
}

enum TCCServiceMap {
  static let servicesByPermissionID: [String: Set<String>] = [
    "screen-recording": ["kTCCServiceScreenCapture"],
    "accessibility": ["kTCCServiceAccessibility"],
    "full-disk-access": ["kTCCServiceSystemPolicyAllFiles"],
    "microphone": ["kTCCServiceMicrophone"],
    "camera": ["kTCCServiceCamera"],
    "location": ["kTCCServiceLocation"],
    "automation": ["kTCCServiceAppleEvents"]
  ]
}

private extension Sequence where Element: Hashable {
  func uniqued() -> [Element] {
    var seen = Set<Element>()
    return filter { seen.insert($0).inserted }
  }
}

