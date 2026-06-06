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
  case notRecorded
  case unavailable
  case unknown

  var displayName: String {
    switch self {
    case .granted: "Granted"
    case .denied: "Denied"
    case .notRecorded: "Not recorded"
    case .unavailable: "Unavailable"
    case .unknown: "Unknown"
    }
  }
}

enum TCCAuthorizationColumn: String, Codable, Hashable {
  case authValue = "auth_value"
  case allowed = "allowed"
  case unavailable = "unavailable"
  case unknown = "unknown"
}

enum TCCEvidenceKind: String, Codable, Hashable {
  case databaseUnreadable
  case databaseMissing
  case noRecordFound
  case matchedGranted
  case matchedDenied
  case matchedUnknown
  case serviceUnmapped
  case systemSettingNotAppScoped
  case queryFailed
  case schemaUnsupported
  case databaseRead
  case legacy

  var title: String {
    switch self {
    case .databaseUnreadable: "Database unreadable"
    case .databaseMissing: "Database missing"
    case .noRecordFound: "No record found"
    case .matchedGranted: "Matched granted"
    case .matchedDenied: "Matched denied"
    case .matchedUnknown: "Matched unknown"
    case .serviceUnmapped: "Service unmapped"
    case .systemSettingNotAppScoped: "System setting"
    case .queryFailed: "Query failed"
    case .schemaUnsupported: "Schema unsupported"
    case .databaseRead: "Database read"
    case .legacy: "Evidence"
    }
  }

  var isDatabaseUnavailable: Bool {
    switch self {
    case .databaseUnreadable, .databaseMissing, .queryFailed, .schemaUnsupported:
      return true
    case .noRecordFound, .matchedGranted, .matchedDenied, .matchedUnknown, .serviceUnmapped, .systemSettingNotAppScoped, .databaseRead, .legacy:
      return false
    }
  }
}

enum PermissionEvidenceSource: String, Codable, Hashable {
  case tcc
  case systemSetting
}

enum PermissionStatusFilter: String, Codable, CaseIterable, Identifiable {
  case any = "Any"
  case recorded = "Recorded"
  case granted = "Granted"
  case denied = "Denied"
  case notRecorded = "Not Recorded"
  case unavailable = "Unavailable"
  case unknown = "Unknown"

  var id: String { rawValue }

  var status: PermissionStatus? {
    switch self {
    case .any, .recorded: nil
    case .granted: .granted
    case .denied: .denied
    case .notRecorded: .notRecorded
    case .unavailable: .unavailable
    case .unknown: .unknown
    }
  }

  func includes(_ status: PermissionStatus) -> Bool {
    switch self {
    case .any:
      return true
    case .recorded:
      return status != .notRecorded
    case .granted, .denied, .notRecorded, .unavailable, .unknown:
      return self.status == status
    }
  }
}

enum SignatureFilter: String, Codable, CaseIterable, Identifiable {
  case any = "Any"
  case signed = "Signed"
  case unsignedOrUnknown = "Unsigned"

  var id: String { rawValue }
}

enum AppSortOrder: String, Codable, CaseIterable, Identifiable {
  case name = "Name"
  case sensitivity = "Sensitivity"
  case permissionStatus = "Status"
  case signature = "Signature"
  case reviewPriority = "Priority"

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
  var evidenceSource: PermissionEvidenceSource = .tcc
}

struct PermissionGrant: Identifiable, Codable, Hashable {
  var id: String { permission.id }

  let permission: PermissionDefinition
  let status: PermissionStatus
  let evidence: String
  var evidenceKind: TCCEvidenceKind = .legacy
  var authorizationColumn: TCCAuthorizationColumn = .unknown

  var statusLine: String {
    switch evidenceKind {
    case .matchedGranted:
      return "TCC record grants this permission."
    case .matchedDenied:
      return "TCC record denies this permission."
    case .matchedUnknown:
      return "TCC record exists, but its authorization value is not recognized."
    case .noRecordFound:
      return "No matching TCC record was found in readable TCC data."
    case .databaseUnreadable:
      return "No configured TCC database could be read."
    case .databaseMissing:
      return "A configured TCC database was not found."
    case .serviceUnmapped:
      return "This permission is not mapped to a TCC service yet."
    case .systemSettingNotAppScoped:
      return "This Privacy & Security setting is not exposed as an app-scoped TCC grant."
    case .queryFailed:
      return "The TCC query failed."
    case .schemaUnsupported:
      return "The TCC database schema was not recognized."
    case .databaseRead:
      return "At least one configured TCC database was read."
    case .legacy:
      return evidence
    }
  }

  var isHighRiskGrant: Bool {
    status == .granted && permission.sensitivity == .high
  }
}

struct PermissionStatusSummary: Equatable {
  let permission: PermissionDefinition
  let granted: Int
  let denied: Int
  let notRecorded: Int
  let unavailable: Int
  let unknown: Int

  var total: Int {
    granted + denied + notRecorded + unavailable + unknown
  }

  var hasKnownState: Bool {
    granted > 0 || denied > 0
  }

  init(permission: PermissionDefinition, apps: [InstalledApp]) {
    self.permission = permission

    if permission.evidenceSource == .systemSetting {
      self.granted = 0
      self.denied = 0
      self.notRecorded = 0
      self.unavailable = 0
      self.unknown = 0
      return
    }

    var granted = 0
    var denied = 0
    var notRecorded = 0
    var unavailable = 0
    var unknown = 0

    for app in apps {
      switch app.grant(for: permission)?.status ?? .notRecorded {
      case .granted:
        granted += 1
      case .denied:
        denied += 1
      case .notRecorded:
        notRecorded += 1
      case .unavailable:
        unavailable += 1
      case .unknown:
        unknown += 1
      }
    }

    self.granted = granted
    self.denied = denied
    self.notRecorded = notRecorded
    self.unavailable = unavailable
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

  var permissionGroups: [PermissionStatus: [PermissionGrant]] {
    Dictionary(grouping: permissions, by: \.status)
      .mapValues { grants in
        grants.sorted {
          if $0.permission.sensitivity == $1.permission.sensitivity {
            return $0.permission.name.localizedCaseInsensitiveCompare($1.permission.name) == .orderedAscending
          }
          return $0.permission.sensitivity < $1.permission.sensitivity
        }
      }
  }

  var highRiskGrants: [PermissionGrant] {
    permissions.filter(\.isHighRiskGrant)
  }

  var reviewPriorityAssessment: ReviewPriorityAssessment {
    ReviewPriorityAssessment(app: self)
  }
}

enum ReviewPriority: String, Codable, CaseIterable, Comparable {
  case high = "High"
  case medium = "Medium"
  case low = "Low"

  static func < (lhs: ReviewPriority, rhs: ReviewPriority) -> Bool {
    let rank: [ReviewPriority: Int] = [.high: 0, .medium: 1, .low: 2]
    return rank[lhs, default: 99] < rank[rhs, default: 99]
  }
}

struct ReviewPriorityAssessment: Codable, Equatable {
  let priority: ReviewPriority
  let reasons: [String]

  init(app: InstalledApp) {
    var reasons: [String] = []
    let highSensitivityGrants = app.permissions
      .filter { $0.status == .granted && $0.permission.sensitivity == .high }
      .map { $0.permission.name }

    if !highSensitivityGrants.isEmpty {
      reasons.append("Granted high-sensitivity permissions: \(highSensitivityGrants.joined(separator: ", ")).")
    }

    if !app.signingInfo.isSigned {
      reasons.append("Code signature is unsigned or unknown.")
    }

    if !highSensitivityGrants.isEmpty && !app.signingInfo.isSigned {
      priority = .high
    } else if !highSensitivityGrants.isEmpty || !app.signingInfo.isSigned {
      priority = .medium
    } else {
      priority = .low
      reasons.append("No high-sensitivity grants or unsigned-signing signal were found in this scan.")
    }

    self.reasons = reasons
  }
}

enum BackgroundItemKind: String, Codable, CaseIterable {
  case launchAgent = "LaunchAgent"
  case launchDaemon = "LaunchDaemon"
  case loginItem = "Login Item"
  case backgroundTask = "Background Task"
  case serviceManagementItem = "Service Management Item"
  case privilegedHelperTool = "Privileged Helper Tool"

  var shortTitle: String {
    switch self {
    case .launchAgent: "Agent"
    case .launchDaemon: "Daemon"
    case .loginItem: "Login"
    case .backgroundTask: "Task"
    case .serviceManagementItem: "Service"
    case .privilegedHelperTool: "Helper"
    }
  }
}

enum BackgroundItemKindFilter: String, Codable, CaseIterable, Identifiable {
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

enum BackgroundItemSortOrder: String, Codable, CaseIterable, Identifiable {
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
  var staleReason: String? = nil
  var evidence: String? = nil
}

struct PrivacyReport: Codable {
  let generatedAt: Date
  let apps: [InstalledApp]
  let backgroundItems: [BackgroundItem]
  var scope: ReportScope = .full
  var filters: ReportFilterDescription? = nil
}

enum ReportScope: String, Codable, Equatable {
  case full
  case filtered
}

struct ReportFilterDescription: Codable, Equatable {
  let appSearchText: String
  let selectedPermissionID: String?
  let permissionStatus: PermissionStatusFilter
  let signature: SignatureFilter
  let appSortOrder: AppSortOrder
  let backgroundSearchText: String
  let backgroundKind: BackgroundItemKindFilter
  let staleOnly: Bool
  let backgroundSortOrder: BackgroundItemSortOrder
}

struct PrivacyReportSummary: Codable, Equatable {
  let scope: ReportScope
  let appCount: Int
  let signedAppCount: Int
  let unsignedOrUnknownAppCount: Int
  let highSensitivityGrantCount: Int
  let backgroundItemCount: Int
  let potentiallyStaleBackgroundItemCount: Int
  let permissionSummaries: [PermissionSummary]
  let backgroundItemKindCounts: [BackgroundItemKind: Int]

  init(report: PrivacyReport) {
    scope = report.scope
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
  let notRecorded: Int
  let unavailable: Int
  let unknown: Int

  init(summary: PermissionStatusSummary) {
    id = summary.permission.id
    name = summary.permission.name
    sensitivity = summary.permission.sensitivity
    granted = summary.granted
    denied = summary.denied
    notRecorded = summary.notRecorded
    unavailable = summary.unavailable
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
      return permissionStatus.includes(.notRecorded)
    }

    return permissionStatus.includes(grant.status)
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
    case .reviewPriority:
      let lhsPriority = lhs.reviewPriorityAssessment.priority
      let rhsPriority = rhs.reviewPriorityAssessment.priority
      return lhsPriority == rhsPriority ? compareNames(lhs, rhs) : lhsPriority < rhsPriority
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
    case .unavailable: return 3
    case .notRecorded: return 4
    }
  }

  private func compareNames(_ lhs: InstalledApp, _ rhs: InstalledApp) -> Bool {
    lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
  }
}

enum DashboardGuidance: Equatable {
  case databaseUnreadable
  case allPermissionStatesUnknown
  case noAppsFound
  case noBackgroundItemsFound

  var title: String {
    switch self {
    case .databaseUnreadable: "TCC Visibility Is Limited"
    case .allPermissionStatesUnknown: "Permission States Are Unknown"
    case .noAppsFound: "No Apps Found"
    case .noBackgroundItemsFound: "No Background Items Found"
    }
  }

  var message: String {
    switch self {
    case .databaseUnreadable:
      return "macOS protects local TCC databases. Permission states are marked unavailable until PermissionPilot can read local TCC data. The app stays read-only; granting Full Disk Access can give the scanner more visibility, but it is optional."
    case .allPermissionStatesUnknown:
      return "No grants or denials were visible in this scan. This can happen on a fresh system or when macOS does not expose the protected database to the app."
    case .noAppsFound:
      return "No .app bundles were found in /Applications or ~/Applications during this scan."
    case .noBackgroundItemsFound:
      return "No LaunchAgents, LaunchDaemons, login items, background tasks, ServiceManagement records, or privileged helper tools were found in scanned locations."
    }
  }
}

enum SystemSettingsLinkStatus: String, CaseIterable, Identifiable {
  case untested = "Untested"
  case testedWorking = "Tested working"
  case testedFailed = "Tested failed"

  var id: String { rawValue }
}

struct DashboardGuidanceEvaluator {
  static func guidance(apps: [InstalledApp], backgroundItems: [BackgroundItem]) -> [DashboardGuidance] {
    var items: [DashboardGuidance] = []

    if apps.isEmpty {
      items.append(.noAppsFound)
    } else {
      let grants = apps.flatMap(\.permissions)
      if grants.contains(where: { $0.evidenceKind.isDatabaseUnavailable }) {
        items.append(.databaseUnreadable)
      } else if !grants.isEmpty && grants.allSatisfy({ $0.status == .unknown }) {
        items.append(.allPermissionStatesUnknown)
      }
    }

    if backgroundItems.isEmpty {
      items.append(.noBackgroundItemsFound)
    }

    return items
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
