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

struct InstalledApp: Identifiable, Codable, Hashable {
  let id: String
  let name: String
  let bundleIdentifier: String?
  let path: String
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
