import AppKit
import SwiftUI

struct DashboardView: View {
  @EnvironmentObject private var store: DashboardStore
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

  var body: some View {
    NavigationSplitView {
      sidebar
    } content: {
      appList
    } detail: {
      detailPane
    }
    .frame(minWidth: 1120, minHeight: 720)
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
    List(selection: $store.selectedPermission) {
      Section("Permissions") {
        ForEach(PermissionCatalog.all) { permission in
          PermissionSidebarRow(
            permission: permission,
            summary: PermissionStatusSummary(permission: permission, apps: store.apps),
            symbol: symbol(for: permission)
          )
            .tag(Optional(permission))
        }
      }

      Section("Scan Summary") {
        Label("\(store.apps.count) apps", systemImage: "app.dashed")
        Label("\(store.backgroundItems.count) background items", systemImage: "gearshape.2")
        Label("\(staleBackgroundItemCount) potentially stale", systemImage: "exclamationmark.triangle")
      }
    }
    .navigationTitle("PermissionPilot")
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

      List(selection: $selectedApp) {
        Section("Installed Apps") {
          if filteredApps.isEmpty {
            ContentUnavailableView("No Matching Apps", systemImage: "line.3.horizontal.decrease.circle")
          } else {
            ForEach(filteredApps) { app in
              AppListRow(app: app, selectedPermission: store.selectedPermission)
                .tag(Optional(app))
            }
          }
        }
      }
    }
    .navigationTitle(store.selectedPermission?.name ?? "Apps")
  }

  @ViewBuilder
  private var detailPane: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        ForEach(guidanceItems, id: \.self) { guidance in
          GuidanceCard(guidance: guidance)
        }

        if let permission = store.selectedPermission {
          PermissionExplanationCard(
            permission: permission,
            summary: PermissionStatusSummary(permission: permission, apps: store.apps),
            linkStatus: bindingForSystemSettingsStatus(permission)
          )
        }

        if let selectedApp {
          AppIdentityDetail(app: selectedApp)
          AppPermissionDetail(app: selectedApp)
        } else {
          EmptySelectionView()
        }

        BackgroundItemsView(
          items: store.backgroundItems,
          selectedItem: $selectedBackgroundItem,
          searchText: $backgroundSearchText,
          kindFilter: $backgroundKindFilter,
          staleOnly: $backgroundStaleOnly,
          sortOrder: $backgroundSortOrder
        )

        if let selectedBackgroundItem {
          BackgroundItemDetail(item: selectedBackgroundItem)
        }

        if let exportMessage {
          Text(exportMessage)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .navigationTitle(selectedApp?.name ?? "Details")
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

  private func symbol(for permission: PermissionDefinition) -> String {
    switch permission.id {
    case "screen-recording": "rectangle.on.rectangle"
    case "accessibility": "figure"
    case "full-disk-access": "internaldrive"
    case "microphone": "mic"
    case "camera": "camera"
    case "location": "location"
    case "automation": "applescript"
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

  private func exportMarkdown(scope: ReportScope) {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.plainText]
    panel.nameFieldStringValue = scope == .filtered ? "permissionpilot-filtered-report.md" : "permissionpilot-report.md"

    guard panel.runModal() == .OK, let url = panel.url else {
      return
    }

    do {
      try ReportExporter.markdown(report: report(for: scope)).write(to: url, atomically: true, encoding: .utf8)
      exportMessage = "Saved Markdown report to \(url.path)."
    } catch {
      exportMessage = "Could not save Markdown report: \(error.localizedDescription)"
    }
  }

  private func exportJSON(scope: ReportScope) {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.json]
    panel.nameFieldStringValue = scope == .filtered ? "permissionpilot-filtered-report.json" : "permissionpilot-report.json"

    guard panel.runModal() == .OK, let url = panel.url else {
      return
    }

    do {
      try ReportExporter.json(report: report(for: scope)).write(to: url)
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

  var body: some View {
    HStack(spacing: 8) {
      Label(permission.name, systemImage: symbol)
      Spacer()
      StatusCountStrip(summary: summary, compact: true)
    }
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

      HStack(spacing: 10) {
        Picker("Status", selection: $permissionStatusFilter) {
          ForEach(PermissionStatusFilter.allCases) { filter in
            Text(filter.rawValue).tag(filter)
          }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 280)

        Picker("Signature", selection: $signatureFilter) {
          ForEach(SignatureFilter.allCases) { filter in
            Text(filter.rawValue).tag(filter)
          }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 280)

        Picker("Sort", selection: $sortOrder) {
          ForEach(AppSortOrder.allCases) { order in
            Text(order.rawValue).tag(order)
          }
        }
        .frame(width: 170)
      }
    }
    .padding(12)
    .background(.background)
  }
}

private struct AppListRow: View {
  let app: InstalledApp
  let selectedPermission: PermissionDefinition?

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(app.name)
          .font(.headline)
        Spacer()

        if let selectedPermission, let grant = app.grant(for: selectedPermission) {
          StatusBadge(status: grant.status)
        }

        ReviewPriorityBadge(priority: app.reviewPriorityAssessment.priority)
        SensitivityBadge(sensitivity: app.highestSensitivity)
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
    .padding(.vertical, 4)
  }
}

private struct PermissionExplanationCard: View {
  let permission: PermissionDefinition
  let summary: PermissionStatusSummary
  @Binding var linkStatus: SystemSettingsLinkStatus

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(permission.name)
          .font(.title2.weight(.semibold))
        SensitivityBadge(sensitivity: permission.sensitivity)
      }

      ExplanationRow(title: "Why this matters", text: permission.whyItMatters)
      ExplanationRow(title: "What an app can do", text: permission.capability)
      ExplanationRow(title: "How to revoke it", text: permission.revokeHint)
      PermissionStatusSummaryView(summary: summary)

      Button {
        SystemSettingsLinker.open(permission)
      } label: {
        Label("Open System Settings", systemImage: "gear")
      }
      .buttonStyle(.borderedProminent)

      Picker("Link QA", selection: $linkStatus) {
        ForEach(SystemSettingsLinkStatus.allCases) { status in
          Text(status.rawValue).tag(status)
        }
      }
      .pickerStyle(.segmented)
      .frame(maxWidth: 420)

      Text("Manual QA status is local runtime state only; it does not modify permissions or System Settings.")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

private struct PermissionStatusSummaryView: View {
  let summary: PermissionStatusSummary

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Current Scan")
        .font(.headline)

      HStack(spacing: 10) {
        StatusCountBadge(title: "Granted", count: summary.granted, color: .green)
        StatusCountBadge(title: "Denied", count: summary.denied, color: .orange)
        StatusCountBadge(title: "Unknown", count: summary.unknown, color: .secondary)
      }

      Text(summary.hasKnownState ? "\(summary.total) apps scanned for this permission." : "No known grants or denials were found for this permission in the current scan.")
        .font(.caption)
        .foregroundStyle(.secondary)
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
      StatusCountPill(count: summary.unknown, color: .secondary)
    }
    .accessibilityLabel("\(summary.granted) granted, \(summary.denied) denied, \(summary.unknown) unknown")
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

private struct StatusCountBadge: View {
  let title: String
  let count: Int
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      Text("\(count)")
        .font(.title3.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(color)
    }
    .frame(width: 96, alignment: .leading)
    .padding(10)
    .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
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
      Text("Permission State")
        .font(.title3.weight(.semibold))

      ForEach([PermissionStatus.granted, .denied, .unknown], id: \.self) { status in
        let grants = app.permissionGroups[status, default: []]
        if !grants.isEmpty {
          Text(status.rawValue.capitalized)
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

  private func reviewHint(for grant: PermissionGrant) -> String {
    if grant.isHighRiskGrant {
      return "Review next: confirm this app still needs \(grant.permission.name)."
    }

    switch grant.status {
    case .granted:
      return "Review when auditing apps that actively use this capability."
    case .denied:
      return "Denied record found; usually lower priority unless unexpected."
    case .unknown:
      return grant.statusLine
    }
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
        ForEach(filteredItems) { item in
          Button {
            selectedItem = item
          } label: {
            BackgroundItemRow(item: item, isSelected: selectedItem?.id == item.id)
          }
          .buttonStyle(.plain)
          Divider()
        }
      }
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

      HStack(spacing: 10) {
        Picker("Kind", selection: $kindFilter) {
          ForEach(BackgroundItemKindFilter.allCases) { filter in
            Text(filter.rawValue).tag(filter)
          }
        }
        .frame(width: 150)

        Toggle("Stale only", isOn: $staleOnly)
          .toggleStyle(.checkbox)
          .fixedSize()

        Picker("Sort", selection: $sortOrder) {
          ForEach(BackgroundItemSortOrder.allCases) { order in
            Text(order.rawValue).tag(order)
          }
        }
        .frame(width: 130)
      }
    }
  }
}

private struct BackgroundItemRow: View {
  let item: BackgroundItem
  let isSelected: Bool

  var body: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 4) {
        Text(item.label)
          .font(.headline)
        Text(item.kind.rawValue)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(item.executable ?? item.path)
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .lineLimit(1)
          .textSelection(.enabled)
      }

      Spacer()

      if item.isPotentiallyStale {
        Label("Potentially stale", systemImage: "exclamationmark.triangle")
          .font(.caption)
          .foregroundStyle(.orange)
      }
    }
    .padding(8)
    .background(isSelected ? Color.accentColor.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
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

private struct GuidanceCard: View {
  let guidance: DashboardGuidance

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: "info.circle")
        Text(guidance.title)
          .font(.headline)
      }

      Text(guidance.message)
        .font(.callout)
        .foregroundStyle(.secondary)

      if guidance == .databaseUnreadable,
         let permission = PermissionCatalog.all.first(where: { $0.id == "full-disk-access" }) {
        Button {
          SystemSettingsLinker.open(permission)
        } label: {
          Label("Open Full Disk Access", systemImage: "internaldrive")
        }
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
    Text(status.rawValue.capitalized)
      .font(.caption.weight(.medium))
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(.quaternary, in: Capsule())
  }
}
