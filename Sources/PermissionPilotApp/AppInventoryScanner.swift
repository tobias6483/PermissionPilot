import AppKit
import Foundation

protocol AppInventoryScanning {
  func scanInstalledApps() -> [InstalledApp]
}

struct AppInventoryScanner: AppInventoryScanning {
  var fileManager: FileManager = .default

  func scanInstalledApps() -> [InstalledApp] {
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
      .map(makeInstalledApp)
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  private func makeInstalledApp(from url: URL) -> InstalledApp {
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
        PermissionGrant(permission: $0, status: .unknown, evidence: "TCC status scan is planned for a later milestone.")
      }
    )
  }
}
