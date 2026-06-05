import Foundation

enum Sensitivity: String, Codable, CaseIterable, Comparable {
  case high = "High"
  case medium = "Medium"
  case low = "Low"

  static func < (lhs: Sensitivity, rhs: Sensitivity) -> Bool {
    let rank: [Sensitivity: Int] = [.high: 0, .medium: 1, .low: 2]
    return rank[lhs, default: 99] < rank[rhs, default: 99]
  }
}

enum PermissionStatus: String, Codable, CaseIterable {
  case granted
  case denied
  case unknown
}

enum PermissionStatusFilter: String, CaseIterable, Identifiable {
  case any = "Any"
  case granted = "Granted"
  case denied = "Denied"
  case unknown = "Unknown"

  var id: String { rawValue }

  var status: PermissionStatus? {
    switch self {
    case .any: nil
    case .granted: .granted
    case .denied: .denied
    case .unknown: .unknown
    }
  }
}

enum SignatureFilter: String, CaseIterable, Identifiable {
  case any = "Any"
  case signed = "Signed"
  case unsignedOrUnknown = "Unsigned"

  var id: String { rawValue }
}

enum AppSortOrder: String, CaseIterable, Identifiable {
  case name = "Name"
  case sensitivity = "Sensitivity"
  case permissionStatus = "Status"
  case signature = "Signature"

  var id: String { rawValue }
}

struct PermissionDefinition: Identifiable, Codable, Hashable {
  let id: String
  let name: String
  let sensitivity: Sensitivity
  let systemSettingsURL: URL?
  let whyItMatters: String
  let capability: String
  let revokeHint: String
}

struct PermissionGrant: Identifiable, Codable, Hashable {
  var id: String { permission.id }

  let permission: PermissionDefinition
  let status: PermissionStatus
  let evidence: String
}

struct PermissionStatusSummary: Equatable {
  let permission: PermissionDefinition
  let granted: Int
  let denied: Int
  let unknown: Int

  var total: Int {
    granted + denied + unknown
  }

  var hasKnownState: Bool {
    granted > 0 || denied > 0
  }

  init(permission: PermissionDefinition, apps: [InstalledApp]) {
    self.permission = permission

    var granted = 0
    var denied = 0
    var unknown = 0

    for app in apps {
      switch app.grant(for: permission)?.status ?? .unknown {
      case .granted:
        granted += 1
      case .denied:
        denied += 1
      case .unknown:
        unknown += 1
      }
    }

    self.granted = granted
    self.denied = denied
    self.unknown = unknown
  }
}

struct CodeSignatureInfo: Codable, Hashable {
  let isSigned: Bool
  let teamIdentifier: String?
  let authorities: [String]
  let identifier: String?
  let evidence: String

  static let unknown = CodeSignatureInfo(
    isSigned: false,
    teamIdentifier: nil,
    authorities: [],
    identifier: nil,
    evidence: "Code signature has not been inspected."
  )
}

struct InstalledApp: Identifiable, Codable, Hashable {
  let id: String
  let name: String
  let bundleIdentifier: String?
  let path: String
  var signingInfo: CodeSignatureInfo = .unknown
  let permissions: [PermissionGrant]

  var highestSensitivity: Sensitivity {
    permissions
      .filter { $0.status == .granted }
      .map(\.permission.sensitivity)
      .sorted()
      .first ?? .low
  }
}

enum BackgroundItemKind: String, Codable, CaseIterable {
  case launchAgent = "LaunchAgent"
  case launchDaemon = "LaunchDaemon"
  case loginItem = "Login Item"
  case backgroundTask = "Background Task"
  case serviceManagementItem = "Service Management Item"
  case privilegedHelperTool = "Privileged Helper Tool"
}

enum BackgroundItemKindFilter: String, CaseIterable, Identifiable {
  case any = "Any"
  case launchAgent = "LaunchAgent"
  case launchDaemon = "LaunchDaemon"
  case loginItem = "Login Item"
  case backgroundTask = "Background Task"
  case serviceManagementItem = "Service"
  case privilegedHelperTool = "Helper"

  var id: String { rawValue }

  var kind: BackgroundItemKind? {
    switch self {
    case .any: nil
    case .launchAgent: .launchAgent
    case .launchDaemon: .launchDaemon
    case .loginItem: .loginItem
    case .backgroundTask: .backgroundTask
    case .serviceManagementItem: .serviceManagementItem
    case .privilegedHelperTool: .privilegedHelperTool
    }
  }
}

enum BackgroundItemSortOrder: String, CaseIterable, Identifiable {
  case label = "Label"
  case kind = "Kind"
  case stale = "Stale"

  var id: String { rawValue }
}

struct BackgroundItem: Identifiable, Codable, Hashable {
  let id: String
  let kind: BackgroundItemKind
  let label: String
  let path: String
  let executable: String?
  let isPotentiallyStale: Bool
}

struct PrivacyReport: Codable {
  let generatedAt: Date
  let apps: [InstalledApp]
  let backgroundItems: [BackgroundItem]
}

struct PrivacyReportSummary: Codable, Equatable {
  let appCount: Int
  let signedAppCount: Int
  let unsignedOrUnknownAppCount: Int
  let highSensitivityGrantCount: Int
  let backgroundItemCount: Int
  let potentiallyStaleBackgroundItemCount: Int
  let permissionSummaries: [PermissionSummary]
  let backgroundItemKindCounts: [BackgroundItemKind: Int]

  init(report: PrivacyReport) {
    appCount = report.apps.count
    signedAppCount = report.apps.filter(\.signingInfo.isSigned).count
    unsignedOrUnknownAppCount = appCount - signedAppCount
    highSensitivityGrantCount = report.apps.reduce(0) { count, app in
      count + app.permissions.filter { $0.status == .granted && $0.permission.sensitivity == .high }.count
    }
    backgroundItemCount = report.backgroundItems.count
    potentiallyStaleBackgroundItemCount = report.backgroundItems.filter(\.isPotentiallyStale).count
    permissionSummaries = PermissionCatalog.all.map { permission in
      PermissionSummary(summary: PermissionStatusSummary(permission: permission, apps: report.apps))
    }
    backgroundItemKindCounts = Dictionary(grouping: report.backgroundItems, by: \.kind)
      .mapValues(\.count)
  }
}

struct PermissionSummary: Codable, Equatable {
  let id: String
  let name: String
  let sensitivity: Sensitivity
  let granted: Int
  let denied: Int
  let unknown: Int

  init(summary: PermissionStatusSummary) {
    id = summary.permission.id
    name = summary.permission.name
    sensitivity = summary.permission.sensitivity
    granted = summary.granted
    denied = summary.denied
    unknown = summary.unknown
  }
}

struct AppListFilter: Equatable {
  var searchText = ""
  var permission: PermissionDefinition?
  var permissionStatus: PermissionStatusFilter = .any
  var signature: SignatureFilter = .any
  var sortOrder: AppSortOrder = .name

  func apply(to apps: [InstalledApp]) -> [InstalledApp] {
    apps
      .filter(matchesSearch)
      .filter(matchesPermission)
      .filter(matchesSignature)
      .sorted(by: areInIncreasingOrder)
  }

  private func matchesSearch(_ app: InstalledApp) -> Bool {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else {
      return true
    }

    return [
      app.name,
      app.bundleIdentifier ?? "",
      app.path,
      app.signingInfo.teamIdentifier ?? "",
      app.signingInfo.identifier ?? ""
    ].contains { value in
      value.localizedCaseInsensitiveContains(query)
    }
  }

  private func matchesPermission(_ app: InstalledApp) -> Bool {
    guard let permission else {
      return true
    }

    guard let grant = app.grant(for: permission) else {
      return false
    }

    guard let requiredStatus = permissionStatus.status else {
      return true
    }

    return grant.status == requiredStatus
  }

  private func matchesSignature(_ app: InstalledApp) -> Bool {
    switch signature {
    case .any:
      return true
    case .signed:
      return app.signingInfo.isSigned
    case .unsignedOrUnknown:
      return !app.signingInfo.isSigned
    }
  }

  private func areInIncreasingOrder(_ lhs: InstalledApp, _ rhs: InstalledApp) -> Bool {
    switch sortOrder {
    case .name:
      return compareNames(lhs, rhs)
    case .sensitivity:
      return lhs.highestSensitivity == rhs.highestSensitivity
        ? compareNames(lhs, rhs)
        : lhs.highestSensitivity < rhs.highestSensitivity
    case .permissionStatus:
      let lhsRank = permissionStatusRank(for: lhs)
      let rhsRank = permissionStatusRank(for: rhs)
      return lhsRank == rhsRank ? compareNames(lhs, rhs) : lhsRank < rhsRank
    case .signature:
      return lhs.signingInfo.isSigned == rhs.signingInfo.isSigned
        ? compareNames(lhs, rhs)
        : lhs.signingInfo.isSigned && !rhs.signingInfo.isSigned
    }
  }

  private func permissionStatusRank(for app: InstalledApp) -> Int {
    guard let permission, let status = app.grant(for: permission)?.status else {
      return 3
    }

    switch status {
    case .granted: return 0
    case .denied: return 1
    case .unknown: return 2
    }
  }

  private func compareNames(_ lhs: InstalledApp, _ rhs: InstalledApp) -> Bool {
    lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
  }
}

extension InstalledApp {
  func grant(for permission: PermissionDefinition) -> PermissionGrant? {
    permissions.first { $0.permission.id == permission.id }
  }
}

struct BackgroundItemListFilter: Equatable {
  var searchText = ""
  var kind: BackgroundItemKindFilter = .any
  var staleOnly = false
  var sortOrder: BackgroundItemSortOrder = .label

  func apply(to items: [BackgroundItem]) -> [BackgroundItem] {
    items
      .filter(matchesSearch)
      .filter(matchesKind)
      .filter(matchesStale)
      .sorted(by: areInIncreasingOrder)
  }

  private func matchesSearch(_ item: BackgroundItem) -> Bool {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else {
      return true
    }

    return [
      item.label,
      item.kind.rawValue,
      item.path,
      item.executable ?? ""
    ].contains { value in
      value.localizedCaseInsensitiveContains(query)
    }
  }

  private func matchesKind(_ item: BackgroundItem) -> Bool {
    guard let requiredKind = kind.kind else {
      return true
    }

    return item.kind == requiredKind
  }

  private func matchesStale(_ item: BackgroundItem) -> Bool {
    !staleOnly || item.isPotentiallyStale
  }

  private func areInIncreasingOrder(_ lhs: BackgroundItem, _ rhs: BackgroundItem) -> Bool {
    switch sortOrder {
    case .label:
      return compareLabels(lhs, rhs)
    case .kind:
      return lhs.kind.rawValue == rhs.kind.rawValue
        ? compareLabels(lhs, rhs)
        : lhs.kind.rawValue.localizedCaseInsensitiveCompare(rhs.kind.rawValue) == .orderedAscending
    case .stale:
      return lhs.isPotentiallyStale == rhs.isPotentiallyStale
        ? compareLabels(lhs, rhs)
        : lhs.isPotentiallyStale && !rhs.isPotentiallyStale
    }
  }

  private func compareLabels(_ lhs: BackgroundItem, _ rhs: BackgroundItem) -> Bool {
    lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
  }
}
