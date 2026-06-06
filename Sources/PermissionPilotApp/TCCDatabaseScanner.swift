import Foundation

protocol TCCDatabaseScanning {
  func scan() -> TCCScanResult
}

struct TCCScanResult {
  let records: [TCCAuthorizationRecord]
  let evidence: String
  var evidenceKind: TCCEvidenceKind = .legacy
  var authorizationColumn: TCCAuthorizationColumn = .unknown
  var readableDatabaseCount: Int = 0
  var scannedDatabaseCount: Int = 1

  func grant(for permission: PermissionDefinition, bundleIdentifier: String?, appPath: String) -> PermissionGrant {
    guard let services = TCCServiceMap.servicesByPermissionID[permission.id] else {
      return PermissionGrant(
        permission: permission,
        status: .unavailable,
        evidence: "No TCC service mapping exists for this permission yet.",
        evidenceKind: .serviceUnmapped,
        authorizationColumn: authorizationColumn
      )
    }

    guard !records.isEmpty else {
      return PermissionGrant(
        permission: permission,
        status: readableDatabaseCount == 0 || evidenceKind.isDatabaseUnavailable ? .unavailable : .notRecorded,
        evidence: evidence,
        evidenceKind: evidenceKind,
        authorizationColumn: authorizationColumn
      )
    }

    let matched = records.filter { record in
      services.contains(record.service) && record.matches(bundleIdentifier: bundleIdentifier, appPath: appPath)
    }

    guard !matched.isEmpty else {
      return PermissionGrant(
        permission: permission,
        status: .notRecorded,
        evidence: "Readable TCC data does not contain a matching record for this app and permission.",
        evidenceKind: .noRecordFound,
        authorizationColumn: authorizationColumn
      )
    }

    let status = matched.contains { $0.status == .granted } ? PermissionStatus.granted : matched[0].status
    let serviceList = matched.map(\.service).uniqued().joined(separator: ", ")
    let kind: TCCEvidenceKind
    switch status {
    case .granted:
      kind = .matchedGranted
    case .denied:
      kind = .matchedDenied
    case .notRecorded:
      kind = .noRecordFound
    case .unavailable:
      kind = evidenceKind
    case .unknown:
      kind = .matchedUnknown
    }

    let automationTargets = matched
      .compactMap(\.indirectObjectIdentifier)
      .filter { !$0.isEmpty && $0 != "UNUSED" }
      .uniqued()
      .joined(separator: ", ")
    let targetEvidence = automationTargets.isEmpty ? "" : " Targets: \(automationTargets)."

    return PermissionGrant(
      permission: permission,
      status: status,
      evidence: "Matched TCC service record: \(serviceList). Authorization column: \(authorizationColumn.rawValue).\(targetEvidence)",
      evidenceKind: kind,
      authorizationColumn: authorizationColumn
    )
  }
}

struct TCCAuthorizationRecord: Hashable {
  let service: String
  let client: String
  let clientType: Int?
  let authorizationValue: Int?
  var indirectObjectIdentifier: String? = nil
  var authorizationColumn: TCCAuthorizationColumn = .unknown

  var status: PermissionStatus {
    switch authorizationColumn {
    case .authValue:
      switch authorizationValue {
      case 2, 3:
        return .granted
      case 0:
        return .denied
      case 1:
        return .unknown
      default:
        return .unknown
      }
    case .allowed:
      switch authorizationValue {
      case 1:
        return .granted
      case 0:
        return .denied
      default:
        return .unknown
      }
    case .unavailable:
      return .unavailable
    case .unknown:
      switch authorizationValue {
      case 2:
        return .granted
      case 0:
        return .denied
      default:
        return .unknown
      }
    }
  }

  func matches(bundleIdentifier: String?, appPath: String) -> Bool {
    if clientType == 0, let bundleIdentifier {
      return client == bundleIdentifier
    }

    if clientType == 1 {
      return client == appPath
    }

    return client == bundleIdentifier || client == appPath
  }
}

struct TCCDatabaseScanner: TCCDatabaseScanning {
  var databaseURL: URL = FileManager.default
    .homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")
  var systemDatabaseURL: URL = URL(fileURLWithPath: "/Library/Application Support/com.apple.TCC/TCC.db")

  func scan() -> TCCScanResult {
    let databaseURLs = [databaseURL, systemDatabaseURL]
    let results = databaseURLs.map(scanDatabase)
    let readableResults = results.filter { $0.evidenceKind == .databaseRead }
    let records = readableResults.flatMap(\.records)
    let evidence = results.map(\.evidence).joined(separator: " ")

    if let firstReadable = readableResults.first {
      return TCCScanResult(
        records: records,
        evidence: evidence,
        evidenceKind: .databaseRead,
        authorizationColumn: firstReadable.authorizationColumn,
        readableDatabaseCount: readableResults.count,
        scannedDatabaseCount: databaseURLs.count
      )
    }

    let firstResult = results.first ?? TCCDatabaseReadResult(
      records: [],
      evidence: "No TCC database paths were configured.",
      evidenceKind: .databaseMissing,
      authorizationColumn: .unavailable
    )

    return TCCScanResult(
      records: [],
      evidence: evidence,
      evidenceKind: firstResult.evidenceKind,
      authorizationColumn: firstResult.authorizationColumn,
      readableDatabaseCount: 0,
      scannedDatabaseCount: databaseURLs.count
    )
  }

  private func scanDatabase(_ databaseURL: URL) -> TCCDatabaseReadResult {
    let scope = databaseURL.path == systemDatabaseURL.path ? "System" : "User"

    guard FileManager.default.fileExists(atPath: databaseURL.path) else {
      return TCCDatabaseReadResult(
        records: [],
        evidence: "\(scope) TCC database was not found at the expected path: \(databaseURL.path).",
        evidenceKind: .databaseMissing,
        authorizationColumn: .unavailable
      )
    }

    let columnsResult = runSQLite(arguments: ["-tabs", databaseURL.path, "PRAGMA table_info(access);"])
    guard columnsResult.exitCode == 0 else {
      return TCCDatabaseReadResult(
        records: [],
        evidence: "\(scope) TCC database was not readable. macOS may require Full Disk Access for this app to inspect local TCC records.",
        evidenceKind: .databaseUnreadable,
        authorizationColumn: .unavailable
      )
    }

    let columns = parseTableInfo(columnsResult.output)
    guard columns.contains("service"), columns.contains("client") else {
      return TCCDatabaseReadResult(
        records: [],
        evidence: "\(scope) TCC access table did not contain expected service/client columns.",
        evidenceKind: .schemaUnsupported,
        authorizationColumn: .unavailable
      )
    }

    let valueColumn: String
    let authorizationColumn: TCCAuthorizationColumn
    if columns.contains("auth_value") {
      valueColumn = "auth_value"
      authorizationColumn = .authValue
    } else if columns.contains("allowed") {
      valueColumn = "allowed"
      authorizationColumn = .allowed
    } else {
      valueColumn = "NULL"
      authorizationColumn = .unavailable
    }

    let clientTypeColumn = columns.contains("client_type") ? "client_type" : "NULL"
    let indirectObjectIdentifierColumn = columns.contains("indirect_object_identifier") ? "indirect_object_identifier" : "NULL"
    let query = "SELECT service, client, \(clientTypeColumn), \(valueColumn), \(indirectObjectIdentifierColumn) FROM access;"
    let recordsResult = runSQLite(arguments: ["-tabs", databaseURL.path, query])

    guard recordsResult.exitCode == 0 else {
      let error = recordsResult.error.trimmingCharacters(in: .whitespacesAndNewlines)
      return TCCDatabaseReadResult(
        records: [],
        evidence: "\(scope) TCC records could not be queried: \(error.isEmpty ? "sqlite3 exited with status \(recordsResult.exitCode)." : error)",
        evidenceKind: .queryFailed,
        authorizationColumn: authorizationColumn
      )
    }

    return TCCDatabaseReadResult(
      records: parseRecords(recordsResult.output, authorizationColumn: authorizationColumn),
      evidence: "Read \(scope.lowercased()) TCC database at \(databaseURL.path) using \(authorizationColumn.rawValue).",
      evidenceKind: .databaseRead,
      authorizationColumn: authorizationColumn
    )
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

  func parseRecords(_ text: String, authorizationColumn: TCCAuthorizationColumn = .unknown) -> [TCCAuthorizationRecord] {
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
          authorizationValue: Int(fields[3]),
          indirectObjectIdentifier: fields.count > 4 ? String(fields[4]) : nil,
          authorizationColumn: authorizationColumn
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

private struct TCCDatabaseReadResult {
  let records: [TCCAuthorizationRecord]
  let evidence: String
  let evidenceKind: TCCEvidenceKind
  let authorizationColumn: TCCAuthorizationColumn
}

enum TCCServiceMap {
  static let servicesByPermissionID: [String: Set<String>] = [
    "screen-recording": ["kTCCServiceScreenCapture"],
    "system-audio-recording": ["kTCCServiceAudioCapture"],
    "accessibility": ["kTCCServiceAccessibility"],
    "full-disk-access": ["kTCCServiceSystemPolicyAllFiles"],
    "files-and-folders": [
      "kTCCServiceSystemPolicyDesktopFolder",
      "kTCCServiceSystemPolicyDocumentsFolder",
      "kTCCServiceSystemPolicyDownloadsFolder",
      "kTCCServiceSystemPolicyNetworkVolumes",
      "kTCCServiceSystemPolicyRemovableVolumes"
    ],
    "app-management": ["kTCCServiceSystemPolicyAppBundles"],
    "keyboard-monitoring": ["kTCCServiceListenEvent"],
    "developer-tools": ["kTCCServiceDeveloperTool"],
    "remote-desktop": ["kTCCServiceRemoteDesktop"],
    "microphone": ["kTCCServiceMicrophone"],
    "camera": ["kTCCServiceCamera"],
    "location": ["kTCCServiceLocation"],
    "motion-fitness": ["kTCCServiceMotion"],
    "home": ["kTCCServiceWillow"],
    "photos": ["kTCCServicePhotos", "kTCCServicePhotosAdd"],
    "contacts": ["kTCCServiceAddressBook"],
    "calendars": ["kTCCServiceCalendar", "kTCCServiceCalendarFullAccess", "kTCCServiceCalendarWriteOnly"],
    "reminders": ["kTCCServiceReminders"],
    "media-library": ["kTCCServiceMediaLibrary"],
    "speech-recognition": ["kTCCServiceSpeechRecognition"],
    "focus": ["kTCCServiceFocusStatus"],
    "local-network": ["kTCCServiceLocalNetwork"],
    "bluetooth": ["kTCCServiceBluetoothAlways", "kTCCServiceBluetoothPeripheral"],
    "browser-passkey-access": ["kTCCServiceWebBrowserPublicKeyCredential"],
    "automation": ["kTCCServiceAppleEvents"]
  ]
}

private extension Sequence where Element: Hashable {
  func uniqued() -> [Element] {
    var seen = Set<Element>()
    return filter { seen.insert($0).inserted }
  }
}
