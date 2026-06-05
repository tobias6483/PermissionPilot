import Foundation

protocol BackgroundItemScanning {
  func scanBackgroundItems() -> [BackgroundItem]
}

struct BackgroundItemScanner: BackgroundItemScanning {
  var fileManager: FileManager = .default
  var privilegedHelperToolDirectories: [URL] = [
    URL(fileURLWithPath: "/Library/PrivilegedHelperTools")
  ]

  func scanBackgroundItems() -> [BackgroundItem] {
    let userLibrary = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library")
    let locations: [(BackgroundItemKind, URL)] = [
      (.launchAgent, userLibrary.appendingPathComponent("LaunchAgents")),
      (.launchAgent, URL(fileURLWithPath: "/Library/LaunchAgents")),
      (.launchDaemon, URL(fileURLWithPath: "/Library/LaunchDaemons"))
    ]

    let plistItems = locations
      .flatMap { kind, url in scanPlists(kind: kind, directory: url) }
    let referencedExecutables = Set(plistItems.compactMap(\.executable))
    let helperToolItems = scanPrivilegedHelperTools(referencedExecutables: referencedExecutables)
    let serviceManagementItems = scanServiceManagementItems()

    return (plistItems + helperToolItems + serviceManagementItems)
      .deduplicatedByID()
      .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
  }

  private func scanPlists(kind: BackgroundItemKind, directory: URL) -> [BackgroundItem] {
    guard let urls = try? fileManager.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    return urls
      .filter { $0.pathExtension == "plist" }
      .map { makeBackgroundItem(kind: kind, url: $0) }
  }

  private func makeBackgroundItem(kind: BackgroundItemKind, url: URL) -> BackgroundItem {
    let plist = (try? Data(contentsOf: url))
      .flatMap { try? PropertyListSerialization.propertyList(from: $0, options: [], format: nil) as? [String: Any] }

    let label = plist?["Label"] as? String ?? url.deletingPathExtension().lastPathComponent
    let executable = executablePath(from: plist)

    return BackgroundItem(
      id: url.path,
      kind: kind,
      label: label,
      path: url.path,
      executable: executable,
      isPotentiallyStale: executable.map { !fileManager.fileExists(atPath: $0) } ?? false
    )
  }

  private func executablePath(from plist: [String: Any]?) -> String? {
    if let program = plist?["Program"] as? String {
      return program
    }

    if let arguments = plist?["ProgramArguments"] as? [String] {
      return arguments.first
    }

    return nil
  }

  func scanPrivilegedHelperTools(referencedExecutables: Set<String>) -> [BackgroundItem] {
    let normalizedReferences = Set(referencedExecutables.map(normalizedFilePath))

    return privilegedHelperToolDirectories.flatMap { directory -> [BackgroundItem] in
      guard let urls = try? fileManager.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
      ) else {
        return []
      }

      return urls.map { url in
        let isReferenced = normalizedReferences.contains(normalizedFilePath(url.path))
        return BackgroundItem(
          id: "privileged-helper:\(url.path)",
          kind: .privilegedHelperTool,
          label: url.lastPathComponent,
          path: url.path,
          executable: url.path,
          isPotentiallyStale: !isReferenced
        )
      }
    }
  }

  private func normalizedFilePath(_ path: String) -> String {
    URL(fileURLWithPath: path).resolvingSymlinksInPath().path
  }

  private func scanServiceManagementItems() -> [BackgroundItem] {
    let result = runSFLToolDumpBTM()
    guard result.exitCode == 0 else {
      return []
    }

    return parseSFLToolDumpBTM(result.output)
  }

  func parseSFLToolDumpBTM(_ text: String) -> [BackgroundItem] {
    text
      .components(separatedBy: "\n #")
      .compactMap(parseSFLToolRecord)
  }

  private func parseSFLToolRecord(_ record: String) -> BackgroundItem? {
    let lines = record
      .split(separator: "\n", omittingEmptySubsequences: false)
      .map(String.init)

    let fields = Dictionary(uniqueKeysWithValues: lines.compactMap(parseKeyValue))
    guard let type = fields["Type"], let kind = kindFromSFLToolType(type) else {
      return nil
    }

    let label = fields["Name"] ?? fields["Identifier"] ?? "Unknown Background Item"
    let identifier = fields["Identifier"] ?? fields["UUID"] ?? label
    let path = normalizeSFLToolPath(fields["URL"]) ?? fields["URL"] ?? identifier
    let executable = normalizeSFLToolPath(fields["Executable Path"]) ?? fields["Executable Path"]
    let stalePath = executable ?? path
    let isStale = isAbsoluteFilePath(stalePath) && !fileManager.fileExists(atPath: stalePath)

    return BackgroundItem(
      id: "sfltool:\(identifier):\(path)",
      kind: kind,
      label: label,
      path: path,
      executable: executable,
      isPotentiallyStale: isStale
    )
  }

  private func parseKeyValue(_ line: String) -> (String, String)? {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    guard let separator = trimmed.firstIndex(of: ":") else {
      return nil
    }

    let key = String(trimmed[..<separator]).trimmingCharacters(in: .whitespaces)
    let value = String(trimmed[trimmed.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
    guard !key.isEmpty, !value.isEmpty, value != "(null)" else {
      return nil
    }

    return (key, value)
  }

  private func kindFromSFLToolType(_ type: String) -> BackgroundItemKind? {
    let normalized = type.lowercased()

    if normalized.contains("login item") {
      return .loginItem
    }

    if normalized.contains("background tasks") {
      return .backgroundTask
    }

    if normalized.contains("launch agent") || normalized.contains("legacy agent") || normalized == "agent" || normalized.hasPrefix("agent ") {
      return .launchAgent
    }

    if normalized.contains("launch daemon") || normalized.contains("legacy daemon") || normalized == "daemon" || normalized.hasPrefix("daemon ") {
      return .launchDaemon
    }

    if normalized.contains("helper") || normalized.contains("service") {
      return .serviceManagementItem
    }

    return nil
  }

  private func normalizeSFLToolPath(_ value: String?) -> String? {
    guard let value, !value.isEmpty else {
      return nil
    }

    if value.hasPrefix("file://"), let url = URL(string: value) {
      return url.path
    }

    return value.removingPercentEncoding ?? value
  }

  private func isAbsoluteFilePath(_ path: String) -> Bool {
    path.hasPrefix("/")
  }

  private func runSFLToolDumpBTM() -> (exitCode: Int32, output: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sfltool")
    process.arguments = ["dumpbtm"]

    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = Pipe()

    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      return (1, "")
    }

    let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    return (process.terminationStatus, output)
  }
}

private extension Array where Element == BackgroundItem {
  func deduplicatedByID() -> [BackgroundItem] {
    var seen = Set<String>()
    return filter { item in
      let key = "\(item.kind.rawValue):\(item.label):\(item.path)"
      return seen.insert(key).inserted
    }
  }
}
