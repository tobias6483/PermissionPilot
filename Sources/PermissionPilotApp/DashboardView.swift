import AppKit
import SwiftUI

private enum DashboardSection {
  case apps
  case systemSetting
  case backgroundItems
  case staleBackgroundItems
}

private struct PermissionSidebarGroup: Identifiable {
  let id: String
  let title: String
  let permissionIDs: [String]

  var permissions: [PermissionDefinition] {
    permissionIDs.compactMap { id in
      PermissionCatalog.all.first { $0.id == id }
    }
  }

  static let all: [PermissionSidebarGroup] = [
    PermissionSidebarGroup(
      id: "system-access",
      title: "System Access",
      permissionIDs: [
        "screen-recording",
        "system-audio-recording",
        "accessibility",
        "full-disk-access",
        "files-and-folders",
        "app-management",
        "keyboard-monitoring",
        "developer-tools",
        "remote-desktop",
        "automation"
      ]
    ),
    PermissionSidebarGroup(
      id: "device-network",
      title: "Device & Network",
      permissionIDs: [
        "microphone",
        "camera",
        "location",
        "motion-fitness",
        "bluetooth",
        "local-network",
        "speech-recognition",
        "focus"
      ]
    ),
    PermissionSidebarGroup(
      id: "personal-data",
      title: "Personal Data",
      permissionIDs: [
        "photos",
        "contacts",
        "calendars",
        "reminders",
        "media-library",
        "home",
        "browser-passkey-access"
      ]
    ),
    PermissionSidebarGroup(
      id: "system-services",
      title: "System & Apple Services",
      permissionIDs: [
        "sensitive-content-warning",
        "blocked-contacts",
        "analytics-improvements",
        "apple-advertising",
        "apple-intelligence-report",
        "filevault",
        "background-security-improvements",
        "blocked-system-software",
        "system-wide-settings-password"
      ]
    )
  ]
}

struct DashboardView: View {
  @EnvironmentObject private var store: DashboardStore
  @AppStorage("developerModeEnabled") private var developerModeEnabled = false
  @State private var selectedApp: InstalledApp?
  @State private var selectedBackgroundItem: BackgroundItem?
  @State private var exportMessage: String?
  @State private var searchText = ""
  @State private var permissionStatusFilter: PermissionStatusFilter = .any
  @State private var signatureFilter: SignatureFilter = .any
  @State private var sortOrder: AppSortOrder = .name
  @State private var backgroundSearchText = ""
  @State private var backgroundKindFilter: BackgroundItemKindFilter = .any
  @State private var backgroundStaleOnly = false
  @State private var backgroundSortOrder: BackgroundItemSortOrder = .label
  @State private var systemSettingsLinkStatuses: [String: SystemSettingsLinkStatus] = [:]
  @State private var selectedDashboardSection: DashboardSection = .apps

  var body: some View {
    NavigationSplitView {
      sidebar
        .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
    } content: {
      contentPane
        .navigationSplitViewColumnWidth(min: 460, ideal: 620, max: 820)
    } detail: {
      detailPane
        .navigationSplitViewColumnWidth(min: 360, ideal: 440, max: 620)
    }
    .navigationSplitViewStyle(.balanced)
    .frame(minWidth: 1060, idealWidth: 1320, minHeight: 720, idealHeight: 820)
    .toolbar {
      ToolbarItemGroup {
        if store.isScanning {
          ProgressView()
            .controlSize(.small)
        }

        Button {
          Task { await store.refresh() }
        } label: {
          Label("Refresh", systemImage: "arrow.clockwise")
        }

        Menu {
          Button("Full Markdown...") {
            exportMarkdown(scope: .full)
          }
          Button("Full JSON...") {
            exportJSON(scope: .full)
          }
          Divider()
          Button("Filtered Markdown...") {
            exportMarkdown(scope: .filtered)
          }
          Button("Filtered JSON...") {
            exportJSON(scope: .filtered)
          }
        } label: {
          Label("Export Report", systemImage: "square.and.arrow.down")
        }
      }
    }
  }

  private var sidebar: some View {
    List {
      ForEach(PermissionSidebarGroup.all) { group in
        Section(group.title) {
          ForEach(group.permissions) { permission in
            Button {
              selectPermission(permission)
            } label: {
              PermissionSidebarRow(
                permission: permission,
                summary: PermissionStatusSummary(permission: permission, apps: store.apps),
                symbol: symbol(for: permission),
                isSelected: store.selectedPermission == permission && selectedDashboardSection.matches(permission)
              )
            }
            .buttonStyle(.plain)
          }
        }
      }

      Section("Scan Summary") {
        Button {
          selectApps(permission: nil)
        } label: {
          SidebarSummaryRow(
            title: "\(store.apps.count) apps",
            symbol: "app.dashed",
            isSelected: selectedDashboardSection == .apps && store.selectedPermission == nil
          )
        }
        .buttonStyle(.plain)

        Button {
          selectBackgroundItems(staleOnly: false)
        } label: {
          SidebarSummaryRow(
            title: "\(store.backgroundItems.count) background items",
            symbol: "gearshape.2",
            isSelected: selectedDashboardSection == .backgroundItems
          )
        }
        .buttonStyle(.plain)

        Button {
          selectBackgroundItems(staleOnly: true)
        } label: {
          SidebarSummaryRow(
            title: "\(staleBackgroundItemCount) potentially stale",
            symbol: "exclamationmark.triangle",
            isSelected: selectedDashboardSection == .staleBackgroundItems
          )
        }
        .buttonStyle(.plain)
      }
    }
    .navigationTitle("PermissionPilot")
  }

  @ViewBuilder
  private var contentPane: some View {
    switch selectedDashboardSection {
    case .apps:
      appList
    case .systemSetting:
      systemSettingPane
    case .backgroundItems, .staleBackgroundItems:
      backgroundItemsList
    }
  }

  private var appList: some View {
    VStack(spacing: 0) {
      AppListControls(
        searchText: $searchText,
        permissionStatusFilter: $permissionStatusFilter,
        signatureFilter: $signatureFilter,
        sortOrder: $sortOrder,
        resultCount: filteredApps.count
      )

      if filteredApps.isEmpty {
        ContentUnavailableView("No Matching Apps", systemImage: "line.3.horizontal.decrease.circle")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List {
          Section("Installed Apps") {
            ForEach(filteredApps) { app in
              Button {
                selectedApp = app
              } label: {
                AppListRow(
                  app: app,
                  selectedPermission: store.selectedPermission,
                  permissionStatusFilter: permissionStatusFilter
                )
                  .contentShape(Rectangle())
                  .background(
                    selectedApp?.id == app.id ? Color.accentColor.opacity(0.10) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8)
                  )
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
    }
    .navigationTitle(store.selectedPermission?.name ?? "Apps")
    .task {
      reconcileSelectedApp()
    }
    .onChange(of: filteredApps.map(\.id)) {
      reconcileSelectedApp()
    }
  }

  private var systemSettingPane: some View {
    ScrollView {
      if let permission = store.selectedPermission {
        SystemSettingOverview(
          permission: permission,
          developerModeEnabled: developerModeEnabled,
          linkStatus: bindingForSystemSettingsStatus(permission)
        )
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        ContentUnavailableView("Select A System Setting", systemImage: "gearshape")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .navigationTitle(store.selectedPermission?.name ?? "System Setting")
  }

  private var backgroundItemsList: some View {
    ScrollView {
      BackgroundItemsView(
        items: store.backgroundItems,
        selectedItem: $selectedBackgroundItem,
        searchText: $backgroundSearchText,
        kindFilter: $backgroundKindFilter,
        staleOnly: $backgroundStaleOnly,
        sortOrder: $backgroundSortOrder,
        showsSelectedDetail: false
      )
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .navigationTitle(selectedDashboardSection == .staleBackgroundItems ? "Potentially Stale" : "Background Items")
  }

  @ViewBuilder
  private var detailPane: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        switch selectedDashboardSection {
        case .apps:
          appsDetailContent
        case .systemSetting:
          systemSettingDetailContent
        case .backgroundItems, .staleBackgroundItems:
          backgroundItemDetailContent
        }

        if let exportMessage {
          Text(exportMessage)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(24)
      .frame(maxWidth: 680, alignment: .leading)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .navigationTitle(detailTitle)
  }

  @ViewBuilder
  private var appsDetailContent: some View {
    ForEach(guidanceItems, id: \.self) { guidance in
      GuidanceCard(guidance: guidance)
    }

    if let permission = store.selectedPermission {
      PermissionExplanationCard(
        permission: permission,
        summary: PermissionStatusSummary(permission: permission, apps: store.apps),
        developerModeEnabled: developerModeEnabled,
        linkStatus: bindingForSystemSettingsStatus(permission)
      )
    }

    if let selectedApp {
      AppIdentityDetail(app: selectedApp)
      AppPermissionDetail(app: selectedApp)
    } else {
      EmptySelectionView()
    }
  }

  @ViewBuilder
  private var backgroundItemDetailContent: some View {
    if let selectedBackgroundItem {
      BackgroundItemDetail(item: selectedBackgroundItem)
    } else {
      EmptyBackgroundItemSelectionView()
    }
  }

  @ViewBuilder
  private var systemSettingDetailContent: some View {
    if let permission = store.selectedPermission {
      SystemSettingDetail(permission: permission)
    } else {
      ContentUnavailableView("Select A System Setting", systemImage: "gearshape")
    }
  }

  private var detailTitle: String {
    switch selectedDashboardSection {
    case .apps:
      return selectedApp?.name ?? "Details"
    case .systemSetting:
      return store.selectedPermission?.name ?? "System Setting"
    case .backgroundItems, .staleBackgroundItems:
      return selectedBackgroundItem?.label ?? "Background Item"
    }
  }

  private var filteredApps: [InstalledApp] {
    AppListFilter(
      searchText: searchText,
      permission: store.selectedPermission,
      permissionStatus: permissionStatusFilter,
      signature: signatureFilter,
      sortOrder: sortOrder
    ).apply(to: store.apps)
  }

  private var filteredBackgroundItems: [BackgroundItem] {
    BackgroundItemListFilter(
      searchText: backgroundSearchText,
      kind: backgroundKindFilter,
      staleOnly: backgroundStaleOnly,
      sortOrder: backgroundSortOrder
    ).apply(to: store.backgroundItems)
  }

  private var guidanceItems: [DashboardGuidance] {
    DashboardGuidanceEvaluator.guidance(apps: store.apps, backgroundItems: store.backgroundItems)
  }

  private var staleBackgroundItemCount: Int {
    store.backgroundItems.filter(\.isPotentiallyStale).count
  }

  private func selectApps(permission: PermissionDefinition?) {
    selectedDashboardSection = .apps
    store.selectedPermission = permission
    permissionStatusFilter = .any
  }

  private func selectPermission(_ permission: PermissionDefinition) {
    store.selectedPermission = permission
    permissionStatusFilter = permission.evidenceSource == .systemSetting ? .any : .recorded
    sortOrder = permission.evidenceSource == .systemSetting ? sortOrder : .permissionStatus
    selectedDashboardSection = permission.evidenceSource == .systemSetting ? .systemSetting : .apps
  }

  private func selectBackgroundItems(staleOnly: Bool) {
    selectedDashboardSection = staleOnly ? .staleBackgroundItems : .backgroundItems
    store.selectedPermission = nil
    backgroundSearchText = ""
    backgroundKindFilter = .any
    backgroundStaleOnly = staleOnly
    backgroundSortOrder = staleOnly ? .stale : .label
  }

  private func symbol(for permission: PermissionDefinition) -> String {
    switch permission.id {
    case "screen-recording": "rectangle.on.rectangle"
    case "system-audio-recording": "speaker.wave.3"
    case "accessibility": "figure"
    case "full-disk-access": "internaldrive"
    case "files-and-folders": "folder"
    case "app-management": "app.badge"
    case "keyboard-monitoring": "keyboard"
    case "developer-tools": "hammer"
    case "remote-desktop": "desktopcomputer"
    case "microphone": "mic"
    case "camera": "camera"
    case "location": "location"
    case "motion-fitness": "figure.run"
    case "photos": "photo.on.rectangle"
    case "contacts": "person.crop.circle"
    case "calendars": "calendar"
    case "reminders": "checklist"
    case "media-library": "music.note"
    case "home": "house"
    case "speech-recognition": "waveform"
    case "focus": "moon"
    case "local-network": "network"
    case "bluetooth": "dot.radiowaves.left.and.right"
    case "browser-passkey-access": "key"
    case "automation": "applescript"
    case "sensitive-content-warning": "eye.trianglebadge.exclamationmark"
    case "blocked-contacts": "person.crop.circle.badge.xmark"
    case "analytics-improvements": "chart.xyaxis.line"
    case "apple-advertising": "megaphone"
    case "apple-intelligence-report": "apple.intelligence"
    case "filevault": "lock"
    case "background-security-improvements": "checkmark.shield"
    case "blocked-system-software": "exclamationmark.shield"
    case "system-wide-settings-password": "person.badge.key"
    default: "lock.shield"
    }
  }

  private func report(for scope: ReportScope) -> PrivacyReport {
    switch scope {
    case .full:
      return store.report
    case .filtered:
      return PrivacyReport(
        generatedAt: Date(),
        apps: filteredApps,
        backgroundItems: filteredBackgroundItems,
        scope: .filtered,
        filters: currentFilterDescription
      )
    }
  }

  private var currentFilterDescription: ReportFilterDescription {
    ReportFilterDescription(
      appSearchText: searchText,
      selectedPermissionID: store.selectedPermission?.id,
      permissionStatus: permissionStatusFilter,
      signature: signatureFilter,
      appSortOrder: sortOrder,
      backgroundSearchText: backgroundSearchText,
      backgroundKind: backgroundKindFilter,
      staleOnly: backgroundStaleOnly,
      backgroundSortOrder: backgroundSortOrder
    )
  }

  private func bindingForSystemSettingsStatus(_ permission: PermissionDefinition) -> Binding<SystemSettingsLinkStatus> {
    Binding(
      get: { systemSettingsLinkStatuses[permission.id, default: .untested] },
      set: { systemSettingsLinkStatuses[permission.id] = $0 }
    )
  }

  private func reconcileSelectedApp() {
    guard let selectedApp else {
      self.selectedApp = filteredApps.first
      return
    }

    if let refreshedApp = filteredApps.first(where: { $0.id == selectedApp.id }) {
      self.selectedApp = refreshedApp
      return
    }

    self.selectedApp = filteredApps.first
  }

  private func exportMarkdown(scope: ReportScope) {
    let report = report(for: scope)
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.plainText]
    panel.nameFieldStringValue = ReportExporter.defaultFileName(scope: scope, format: .markdown, generatedAt: report.generatedAt)

    guard panel.runModal() == .OK, let url = panel.url else {
      return
    }

    do {
      try ReportExporter.markdown(report: report).write(to: url, atomically: true, encoding: .utf8)
      exportMessage = "Saved Markdown report to \(url.path)."
    } catch {
      exportMessage = "Could not save Markdown report: \(error.localizedDescription)"
    }
  }

  private func exportJSON(scope: ReportScope) {
    let report = report(for: scope)
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.json]
    panel.nameFieldStringValue = ReportExporter.defaultFileName(scope: scope, format: .json, generatedAt: report.generatedAt)

    guard panel.runModal() == .OK, let url = panel.url else {
      return
    }

    do {
      try ReportExporter.json(report: report).write(to: url)
      exportMessage = "Saved JSON report to \(url.path)."
    } catch {
      exportMessage = "Could not save JSON report: \(error.localizedDescription)"
    }
  }
}

private struct PermissionSidebarRow: View {
  let permission: PermissionDefinition
  let summary: PermissionStatusSummary
  let symbol: String
  let isSelected: Bool

  var body: some View {
    HStack(spacing: 8) {
      Label(permission.name, systemImage: symbol)
        .lineLimit(1)
      Spacer()
      if permission.evidenceSource == .systemSetting {
        Text("System")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(Color.secondary.opacity(0.12), in: Capsule())
      } else {
        StatusCountStrip(summary: summary, compact: true)
          .layoutPriority(1)
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .contentShape(Rectangle())
    .background(isSelected ? Color.primary.opacity(0.06) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
  }
}

private extension DashboardSection {
  func matches(_ permission: PermissionDefinition) -> Bool {
    switch self {
    case .apps:
      return permission.evidenceSource == .tcc
    case .systemSetting:
      return permission.evidenceSource == .systemSetting
    case .backgroundItems, .staleBackgroundItems:
      return false
    }
  }
}

private struct SidebarSummaryRow: View {
  let title: String
  let symbol: String
  var isSelected = false

  var body: some View {
    Label(title, systemImage: symbol)
      .lineLimit(1)
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
      .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct AppListControls: View {
  @Binding var searchText: String
  @Binding var permissionStatusFilter: PermissionStatusFilter
  @Binding var signatureFilter: SignatureFilter
  @Binding var sortOrder: AppSortOrder
  let resultCount: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        TextField("Search apps, bundle IDs, teams, or paths", text: $searchText)
          .textFieldStyle(.roundedBorder)

        Text("\(resultCount)")
          .font(.caption.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(.secondary)
          .frame(minWidth: 34, alignment: .trailing)
      }

      ViewThatFits(in: .horizontal) {
        filterControls
        VStack(alignment: .leading, spacing: 10) {
          statusSignatureControls
          sortControl
        }
        VStack(alignment: .leading, spacing: 10) {
          statusControl
          signatureControl
          sortControl
        }
      }
    }
    .padding(12)
    .background(.background)
  }

  private var filterControls: some View {
    HStack(spacing: 10) {
      statusSignatureControls
      sortControl
    }
  }

  private var statusSignatureControls: some View {
    HStack(spacing: 10) {
      statusControl
      signatureControl
    }
  }

  private var statusControl: some View {
    HStack(spacing: 6) {
      Text("Status")
        .foregroundStyle(.secondary)

      Picker("Status", selection: $permissionStatusFilter) {
        ForEach(PermissionStatusFilter.allCases) { filter in
          Text(filter.rawValue).tag(filter)
        }
      }
      .pickerStyle(.menu)
      .labelsHidden()
      .frame(width: 150)
    }
    .font(.body)
  }

  private var signatureControl: some View {
    Picker("Signature", selection: $signatureFilter) {
      ForEach(SignatureFilter.allCases) { filter in
        Text(filter.rawValue).tag(filter)
      }
    }
    .pickerStyle(.segmented)
    .frame(width: 260)
  }

  private var sortControl: some View {
    Picker("Sort", selection: $sortOrder) {
      ForEach(AppSortOrder.allCases) { order in
        Text(order.rawValue).tag(order)
      }
    }
    .frame(width: 160)
  }
}

private struct AppListRow: View {
  let app: InstalledApp
  let selectedPermission: PermissionDefinition?
  let permissionStatusFilter: PermissionStatusFilter

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(app.name)
          .font(.headline)
          .lineLimit(1)
        Spacer()

        if let selectedPermission,
           let grant = app.grant(for: selectedPermission),
           !grant.evidenceKind.isDatabaseUnavailable,
           grant.evidenceKind != .systemSettingNotAppScoped,
           shouldShowSelectedPermissionBadge(grant) {
          StatusBadge(status: grant.status)
        }

        ReviewPriorityBadge(priority: app.reviewPriorityAssessment.priority)
        AppAccessBadge(sensitivity: app.highestSensitivity)
      }

      Text(app.bundleIdentifier ?? "No bundle identifier")
        .font(.caption)
        .foregroundStyle(.secondary)

      Label(app.signingInfo.isSigned ? "Signed" : "Unsigned or unknown", systemImage: app.signingInfo.isSigned ? "checkmark.seal" : "questionmark.diamond")
        .font(.caption2)
        .foregroundStyle(app.signingInfo.isSigned ? .green : .orange)

      Text(app.path)
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .lineLimit(1)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
  }

  private func shouldShowSelectedPermissionBadge(_ grant: PermissionGrant) -> Bool {
    grant.status != .notRecorded || permissionStatusFilter == .any || permissionStatusFilter == .notRecorded
  }
}

private struct PermissionExplanationCard: View {
  let permission: PermissionDefinition
  let summary: PermissionStatusSummary
  let developerModeEnabled: Bool
  @Binding var linkStatus: SystemSettingsLinkStatus

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(permission.name)
          .font(.title2.weight(.semibold))
          .lineLimit(1)
        SensitivityBadge(sensitivity: permission.sensitivity)
      }

      if summary.unavailable > 0 {
        Label("\(summary.unavailable) apps unavailable until TCC data can be read", systemImage: "lock.shield")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 5)
          .background(.quaternary.opacity(0.6), in: Capsule())
      }

      ExplanationRow(title: "Why this matters", text: permission.whyItMatters)
      ExplanationRow(title: "What an app can do", text: permission.capability)
      ExplanationRow(title: "How to revoke it", text: permission.revokeHint)

      if developerModeEnabled {
        Divider()

        Picker("Link QA", selection: $linkStatus) {
          ForEach(SystemSettingsLinkStatus.allCases) { status in
            Text(status.rawValue).tag(status)
          }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: .infinity)

        Text("Developer-only local QA state; it does not modify permissions or System Settings.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct SystemSettingOverview: View {
  let permission: PermissionDefinition
  let developerModeEnabled: Bool
  @Binding var linkStatus: SystemSettingsLinkStatus

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 8) {
        Text(permission.name)
          .font(.title2.weight(.semibold))
        SensitivityBadge(sensitivity: permission.sensitivity)
        Text("System setting")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(.quaternary.opacity(0.6), in: Capsule())
      }

      Text("This category is part of macOS Privacy & Security coverage, but it is not a per-app permission grant.")
        .font(.callout)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      ExplanationRow(title: "Why this matters", text: permission.whyItMatters)
      ExplanationRow(title: "What macOS can do", text: permission.capability)
      ExplanationRow(title: "How to review it", text: permission.revokeHint)

      if developerModeEnabled {
        Divider()

        Picker("Link QA", selection: $linkStatus) {
          ForEach(SystemSettingsLinkStatus.allCases) { status in
            Text(status.rawValue).tag(status)
          }
        }
        .pickerStyle(.segmented)

        Text("Developer-only local QA state; it does not modify permissions or System Settings.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct SystemSettingDetail: View {
  let permission: PermissionDefinition

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("System Setting")
        .font(.title3.weight(.semibold))

      IdentityRow(title: "Category", value: permission.name)
      IdentityRow(title: "Evidence", value: "Not app-scoped")
      IdentityRow(title: "Scope", value: "Mac, Apple service, MDM policy, or security posture")

      ExplanationRow(
        title: "Why this is not shown under each app",
        text: "This setting does not answer whether a selected app has access. It answers how macOS or an Apple service is configured, so showing it under every app would be misleading."
      )

      ExplanationRow(
        title: "Examples",
        text: "FileVault applies to disk encryption, Analytics & Improvements applies to diagnostic sharing, and Apple Advertising applies to Apple ad personalization. Those are system-level states, not grants owned by ChatGPT, Safari, VS Code, or any other app."
      )
    }
  }
}

private struct StatusCountStrip: View {
  let summary: PermissionStatusSummary
  let compact: Bool

  var body: some View {
    HStack(spacing: compact ? 4 : 8) {
      StatusCountPill(count: summary.granted, color: .green)
      StatusCountPill(count: summary.denied, color: .orange)
      if summary.unknown > 0 {
        StatusCountPill(count: summary.unknown, color: .purple)
      }
      if summary.unavailable > 0 {
        StatusCountPill(count: summary.unavailable, color: .red)
      }
      StatusCountPill(count: summary.notRecorded, color: .secondary)
    }
    .accessibilityLabel("\(summary.granted) granted, \(summary.denied) denied, \(summary.unknown) unknown, \(summary.unavailable) unavailable, \(summary.notRecorded) not recorded")
  }
}

private struct StatusCountPill: View {
  let count: Int
  let color: Color

  var body: some View {
    Text("\(count)")
      .font(.caption2.weight(.semibold))
      .monospacedDigit()
      .foregroundStyle(color)
      .frame(minWidth: 18)
      .padding(.horizontal, 5)
      .padding(.vertical, 2)
      .background(color.opacity(0.12), in: Capsule())
  }
}

private struct AppIdentityDetail: View {
  let app: InstalledApp

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("App Identity")
        .font(.title3.weight(.semibold))

      IdentityRow(title: "Bundle ID", value: app.bundleIdentifier ?? "Unknown")
      IdentityRow(title: "Code Signature", value: app.signingInfo.isSigned ? "Signed" : "Unsigned or unknown")
      IdentityRow(title: "Review Priority", value: app.reviewPriorityAssessment.priority.rawValue)

      if let teamIdentifier = app.signingInfo.teamIdentifier {
        IdentityRow(title: "Team ID", value: teamIdentifier)
      }

      if let identifier = app.signingInfo.identifier {
        IdentityRow(title: "Signing ID", value: identifier)
      }

      if !app.signingInfo.authorities.isEmpty {
        IdentityRow(title: "Authority", value: app.signingInfo.authorities.joined(separator: " -> "))
      }

      Text(app.signingInfo.evidence)
        .font(.caption)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 4) {
        Text("Why this priority")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        ForEach(app.reviewPriorityAssessment.reasons, id: \.self) { reason in
          Text(reason)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}

private struct AppPermissionDetail: View {
  let app: InstalledApp

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Selected App Permissions")
        .font(.title3.weight(.semibold))

      if isPermissionEvidenceUnavailable {
        PermissionEvidenceLimitedNotice()
      } else if recordedPermissions.isEmpty {
        PermissionEvidenceEmptyNotice()
      } else {
        ForEach([PermissionStatus.granted, .denied, .unknown, .unavailable], id: \.self) { status in
          let grants = recordedPermissionsByStatus[status, default: []]
          if !grants.isEmpty {
            Text(status.displayName)
              .font(.headline)

            ForEach(grants) { grant in
              HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                  HStack(spacing: 6) {
                    Text(grant.permission.name)
                      .font(.subheadline.weight(.semibold))
                    if grant.isHighRiskGrant {
                      Label("High-risk grant", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                    }
                  }

                  Text(reviewHint(for: grant))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                  HStack(spacing: 8) {
                    EvidenceKindBadge(kind: grant.evidenceKind)
                    Text("Column: \(grant.authorizationColumn.rawValue)")
                      .font(.caption2)
                      .foregroundStyle(.secondary)
                  }

                  Text(grant.evidence)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                }

                Spacer()
                StatusBadge(status: grant.status)
              }
              Divider()
            }
          }
        }
      }
    }
  }

  private var isPermissionEvidenceUnavailable: Bool {
    !app.permissions.isEmpty && app.permissions.allSatisfy { $0.evidenceKind.isDatabaseUnavailable }
  }

  private var recordedPermissions: [PermissionGrant] {
    app.permissions.filter {
      $0.status != .notRecorded && $0.evidenceKind != .systemSettingNotAppScoped
    }
  }

  private var recordedPermissionsByStatus: [PermissionStatus: [PermissionGrant]] {
    Dictionary(grouping: recordedPermissions, by: \.status)
      .mapValues { grants in
        grants.sorted {
          if $0.permission.sensitivity == $1.permission.sensitivity {
            return $0.permission.name.localizedCaseInsensitiveCompare($1.permission.name) == .orderedAscending
          }
          return $0.permission.sensitivity < $1.permission.sensitivity
        }
      }
  }

  private func reviewHint(for grant: PermissionGrant) -> String {
    if grant.isHighRiskGrant {
      return "Review next: confirm this app still needs \(grant.permission.name)."
    }

    switch grant.status {
    case .granted:
      return "Review when auditing apps that actively use this capability."
    case .denied:
      return "Denied record found; usually lower priority unless unexpected."
    case .notRecorded:
      return "No recorded grant or denial was found for this permission."
    case .unavailable:
      return grant.statusLine
    case .unknown:
      return grant.statusLine
    }
  }
}

private struct PermissionEvidenceLimitedNotice: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Label("Permission evidence is limited", systemImage: "lock.shield")
        .font(.subheadline.weight(.semibold))

      Text("PermissionPilot cannot read local TCC databases yet, so per-app grants and denials are hidden instead of repeating unknown rows. Use the Full Disk Access prompt above to improve scan visibility.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      Text("Current selected-app permission state: Unavailable")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct PermissionEvidenceEmptyNotice: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Label("No recorded permissions", systemImage: "checkmark.circle")
        .font(.subheadline.weight(.semibold))

      Text("Readable TCC data does not contain recorded grants or denials for this app.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct IdentityRow: View {
  let title: String
  let value: String

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .frame(width: 110, alignment: .leading)
      Text(value)
        .font(.caption)
        .textSelection(.enabled)
        .lineLimit(3)
        .truncationMode(.middle)
    }
  }
}

private struct BackgroundItemsView: View {
  let items: [BackgroundItem]
  @Binding var selectedItem: BackgroundItem?
  @Binding var searchText: String
  @Binding var kindFilter: BackgroundItemKindFilter
  @Binding var staleOnly: Bool
  @Binding var sortOrder: BackgroundItemSortOrder
  var showsSelectedDetail = true

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        Text("Background Items")
          .font(.title3.weight(.semibold))

        Spacer()

        Text("\(filteredItems.count) of \(items.count)")
          .font(.caption.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(.secondary)
      }

      BackgroundItemKindSummary(items: items)

      BackgroundItemControls(
        searchText: $searchText,
        kindFilter: $kindFilter,
        staleOnly: $staleOnly,
        sortOrder: $sortOrder
      )

      if items.isEmpty {
        ContentUnavailableView("No Background Items Found", systemImage: "gearshape.2")
      } else if filteredItems.isEmpty {
        ContentUnavailableView("No Matching Background Items", systemImage: "line.3.horizontal.decrease.circle")
      } else {
        VStack(spacing: 0) {
          BackgroundItemTableHeader()

          ForEach(filteredItems) { item in
            Button {
              selectedItem = item
            } label: {
              BackgroundItemRow(item: item, isSelected: selectedItem?.id == item.id)
            }
            .buttonStyle(.plain)

            if item.id != filteredItems.last?.id {
              Divider()
            }
          }
        }
        .overlay {
          RoundedRectangle(cornerRadius: 8)
            .stroke(.quaternary)
        }

        if showsSelectedDetail, let selectedItem {
          BackgroundItemDetail(item: selectedItem)
        }
      }
    }
    .task {
      reconcileSelectedItem()
    }
    .onChange(of: filteredItems.map(\.id)) {
      reconcileSelectedItem()
    }
  }

  private var filteredItems: [BackgroundItem] {
    BackgroundItemListFilter(
      searchText: searchText,
      kind: kindFilter,
      staleOnly: staleOnly,
      sortOrder: sortOrder
    ).apply(to: items)
  }

  private func reconcileSelectedItem() {
    guard let selectedItem else {
      self.selectedItem = filteredItems.first
      return
    }

    if let refreshedItem = filteredItems.first(where: { $0.id == selectedItem.id }) {
      self.selectedItem = refreshedItem
      return
    }

    self.selectedItem = filteredItems.first
  }
}

private struct BackgroundItemKindSummary: View {
  let items: [BackgroundItem]

  var body: some View {
    if !items.isEmpty {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], alignment: .leading, spacing: 8) {
        ForEach(BackgroundItemKind.allCases, id: \.self) { kind in
          let count = items.filter { $0.kind == kind }.count
          if count > 0 {
            HStack(spacing: 6) {
              Text(kind.shortTitle)
                .lineLimit(1)
              Spacer(minLength: 4)
              Text("\(count)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
          }
        }
      }
    }
  }
}

private struct BackgroundItemControls: View {
  @Binding var searchText: String
  @Binding var kindFilter: BackgroundItemKindFilter
  @Binding var staleOnly: Bool
  @Binding var sortOrder: BackgroundItemSortOrder

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      TextField("Search labels, paths, executables, or kinds", text: $searchText)
        .textFieldStyle(.roundedBorder)

      ViewThatFits(in: .horizontal) {
        backgroundFilterControls
        VStack(alignment: .leading, spacing: 10) {
          backgroundKindControls
          sortControl
        }
      }
    }
  }

  private var backgroundFilterControls: some View {
    HStack(spacing: 10) {
      backgroundKindControls
      sortControl
    }
  }

  private var backgroundKindControls: some View {
    HStack(spacing: 10) {
      kindControl

      Toggle("Stale only", isOn: $staleOnly)
        .toggleStyle(.checkbox)
        .fixedSize()
    }
  }

  private var kindControl: some View {
    Picker("Kind", selection: $kindFilter) {
      ForEach(BackgroundItemKindFilter.allCases) { filter in
        Text(filter.rawValue).tag(filter)
      }
    }
    .frame(width: 150)
  }

  private var sortControl: some View {
    Picker("Sort", selection: $sortOrder) {
      ForEach(BackgroundItemSortOrder.allCases) { order in
        Text(order.rawValue).tag(order)
      }
    }
    .frame(width: 130)
  }
}

private struct BackgroundItemTableHeader: View {
  var body: some View {
    HStack(spacing: 12) {
      Text("Item")
        .frame(maxWidth: .infinity, alignment: .leading)
      Text("Kind")
        .frame(width: 118, alignment: .leading)
      Text("Signal")
        .frame(width: 92, alignment: .trailing)
    }
    .font(.caption.weight(.semibold))
    .foregroundStyle(.secondary)
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(.quaternary.opacity(0.35))
  }
}

private struct BackgroundItemRow: View {
  let item: BackgroundItem
  let isSelected: Bool

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(item.label)
          .font(.subheadline.weight(.semibold))
          .lineLimit(1)
        Text(item.executable ?? item.path)
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .lineLimit(1)
          .textSelection(.enabled)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Text(item.kind.shortTitle)
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .frame(width: 118, alignment: .leading)

      BackgroundItemSignalBadge(item: item)
        .frame(width: 92, alignment: .trailing)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .contentShape(Rectangle())
    .background(isSelected ? Color.accentColor.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct BackgroundItemSignalBadge: View {
  let item: BackgroundItem

  var body: some View {
    if item.isPotentiallyStale {
      Label("Stale", systemImage: "exclamationmark.triangle")
        .labelStyle(.titleAndIcon)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.orange)
    } else {
      Text("OK")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.green)
    }
  }
}

private struct BackgroundItemDetail: View {
  let item: BackgroundItem

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Background Item Detail")
        .font(.title3.weight(.semibold))

      IdentityRow(title: "Kind", value: item.kind.rawValue)
      IdentityRow(title: "Label", value: item.label)
      IdentityRow(title: "Path", value: item.path)
      IdentityRow(title: "Executable", value: item.executable ?? "Unknown")
      IdentityRow(title: "Stale", value: item.isPotentiallyStale ? "Potentially stale" : "No stale signal")
      IdentityRow(title: "Stale Reason", value: item.staleReason ?? "None")
      IdentityRow(title: "Evidence", value: item.evidence ?? "No additional evidence")

      ExplanationRow(
        title: "Why this matters",
        text: "Background items can start code outside the main app launch path. A stale item is a review signal that a helper, launch record, or login item may no longer match an installed executable."
      )
    }
  }
}

private struct EmptySelectionView: View {
  var body: some View {
    ContentUnavailableView(
      "Select An App",
      systemImage: "sidebar.left",
      description: Text("Choose an installed app to inspect its current permission inventory.")
    )
  }
}

private struct EmptyBackgroundItemSelectionView: View {
  var body: some View {
    ContentUnavailableView(
      "Select A Background Item",
      systemImage: "gearshape.2",
      description: Text("Choose a launch record, login item, background task, or helper to inspect its evidence.")
    )
  }
}

private struct GuidanceCard: View {
  let guidance: DashboardGuidance

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: "info.circle")
        Text(guidance.title)
          .font(.headline)
          .fixedSize(horizontal: false, vertical: true)
      }

      Text(guidance.message)
        .font(.callout)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      if guidance == .databaseUnreadable,
         let permission = PermissionCatalog.all.first(where: { $0.id == "full-disk-access" }) {
        Button {
          SystemSettingsLinker.open(permission)
        } label: {
          Label("Grant Full Disk Access", systemImage: "internaldrive")
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .padding(12)
    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct ExplanationRow: View {
  let title: String
  let text: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.headline)
      Text(text)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

private struct SensitivityBadge: View {
  let sensitivity: Sensitivity

  var body: some View {
    Text(sensitivity.rawValue)
      .font(.caption.weight(.semibold))
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(color.opacity(0.14), in: Capsule())
      .foregroundStyle(color)
  }

  private var color: Color {
    switch sensitivity {
    case .high: .red
    case .medium: .orange
    case .low: .green
    }
  }
}

private struct ReviewPriorityBadge: View {
  let priority: ReviewPriority

  var body: some View {
    Text("\(priority.rawValue) priority")
      .font(.caption.weight(.semibold))
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(color.opacity(0.14), in: Capsule())
      .foregroundStyle(color)
  }

  private var color: Color {
    switch priority {
    case .high: .red
    case .medium: .orange
    case .low: .secondary
    }
  }
}

private struct AppAccessBadge: View {
  let sensitivity: Sensitivity

  var body: some View {
    Text("\(sensitivity.rawValue) access")
      .font(.caption.weight(.semibold))
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(color.opacity(0.14), in: Capsule())
      .foregroundStyle(color)
  }

  private var color: Color {
    switch sensitivity {
    case .high: .red
    case .medium: .orange
    case .low: .green
    }
  }
}

private struct EvidenceKindBadge: View {
  let kind: TCCEvidenceKind

  var body: some View {
    Text(kind.title)
      .font(.caption2.weight(.semibold))
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(.quaternary, in: Capsule())
  }
}

private struct StatusBadge: View {
  let status: PermissionStatus

  var body: some View {
    Text(status.displayName)
      .font(.caption.weight(.medium))
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(.quaternary, in: Capsule())
  }
}
