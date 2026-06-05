import AppKit
import Foundation

protocol AppInventoryScanning {
  func scanInstalledApps() -> [InstalledApp]
}

struct AppInventoryScanner: AppInventoryScanning {
  var fileManager: FileManager = .default
  var tccScanner: TCCDatabaseScanning = TCCDatabaseScanner()

  func scanInstalledApps() -> [InstalledApp] {
    let tccScan = tccScanner.scan()
    let roots = [
      "/Applications",
      fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
    ]

    let appURLs = roots.flatMap { root -> [URL] in
      let rootURL = URL(fileURLWithPath: root)
      guard let enumerator = fileManager.enumerator(
        at: rootURL,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
      ) else {
        return []
      }

      return enumerator.compactMap { item in
        guard let url = item as? URL, url.pathExtension == "app" else {
          return nil
        }
        return url
      }
    }

    return appURLs
      .map { makeInstalledApp(from: $0, tccScan: tccScan) }
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  private func makeInstalledApp(from url: URL, tccScan: TCCScanResult) -> InstalledApp {
    let bundle = Bundle(url: url)
    let displayName = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    let bundleName = bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
    let name = displayName ?? bundleName ?? url.deletingPathExtension().lastPathComponent

    return InstalledApp(
      id: bundle?.bundleIdentifier ?? url.path,
      name: name,
      bundleIdentifier: bundle?.bundleIdentifier,
      path: url.path,
      permissions: PermissionCatalog.all.map {
        tccScan.grant(for: $0, bundleIdentifier: bundle?.bundleIdentifier, appPath: url.path)
      }
    )
  }
}
