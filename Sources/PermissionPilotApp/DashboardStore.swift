import Foundation

@MainActor
final class DashboardStore: ObservableObject {
  @Published private(set) var apps: [InstalledApp] = []
  @Published private(set) var backgroundItems: [BackgroundItem] = []
  @Published private(set) var isScanning = false
  @Published var selectedPermission: PermissionDefinition? = PermissionCatalog.all.first

  private let appScanner: AppInventoryScanning
  private let backgroundScanner: BackgroundItemScanning

  init(
    appScanner: AppInventoryScanning = AppInventoryScanner(),
    backgroundScanner: BackgroundItemScanning = BackgroundItemScanner()
  ) {
    self.appScanner = appScanner
    self.backgroundScanner = backgroundScanner
  }

  func refresh() async {
    isScanning = true
    defer { isScanning = false }

    apps = appScanner.scanInstalledApps()
    backgroundItems = backgroundScanner.scanBackgroundItems()
  }

  var report: PrivacyReport {
    PrivacyReport(generatedAt: Date(), apps: apps, backgroundItems: backgroundItems)
  }
}
