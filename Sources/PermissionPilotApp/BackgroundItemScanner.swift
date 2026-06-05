import Foundation

protocol BackgroundItemScanning {
  func scanBackgroundItems() -> [BackgroundItem]
}

struct BackgroundItemScanner: BackgroundItemScanning {
  var fileManager: FileManager = .default

  func scanBackgroundItems() -> [BackgroundItem] {
    let userLibrary = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library")
    let locations: [(BackgroundItemKind, URL)] = [
      (.launchAgent, userLibrary.appendingPathComponent("LaunchAgents")),
      (.launchAgent, URL(fileURLWithPath: "/Library/LaunchAgents")),
      (.launchDaemon, URL(fileURLWithPath: "/Library/LaunchDaemons"))
    ]

    return locations
      .flatMap { kind, url in scanPlists(kind: kind, directory: url) }
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
}
