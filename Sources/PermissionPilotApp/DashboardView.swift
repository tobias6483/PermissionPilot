import AppKit
import SwiftUI

struct DashboardView: View {
  @EnvironmentObject private var store: DashboardStore
  @State private var selectedApp: InstalledApp?
  @State private var exportMessage: String?

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
          Button("Markdown...") {
            exportMarkdown()
          }
          Button("JSON...") {
            exportJSON()
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
          Label(permission.name, systemImage: symbol(for: permission))
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
    List(selection: $selectedApp) {
      Section("Installed Apps") {
        ForEach(filteredApps) { app in
          VStack(alignment: .leading, spacing: 6) {
            HStack {
              Text(app.name)
                .font(.headline)
              Spacer()
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
          .tag(Optional(app))
        }
      }
    }
    .navigationTitle(store.selectedPermission?.name ?? "Apps")
  }

  @ViewBuilder
  private var detailPane: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        if let permission = store.selectedPermission {
          PermissionExplanationCard(permission: permission)
        }

        if let selectedApp {
          AppIdentityDetail(app: selectedApp)
          AppPermissionDetail(app: selectedApp)
        } else {
          EmptySelectionView()
        }

        BackgroundItemsView(items: store.backgroundItems)

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
    guard let selectedPermission = store.selectedPermission else {
      return store.apps
    }

    return store.apps.filter { app in
      app.permissions.contains { $0.permission.id == selectedPermission.id }
    }
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

  private func exportMarkdown() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.plainText]
    panel.nameFieldStringValue = "permissionpilot-report.md"

    guard panel.runModal() == .OK, let url = panel.url else {
      return
    }

    do {
      try ReportExporter.markdown(report: store.report).write(to: url, atomically: true, encoding: .utf8)
      exportMessage = "Saved Markdown report to \(url.path)."
    } catch {
      exportMessage = "Could not save Markdown report: \(error.localizedDescription)"
    }
  }

  private func exportJSON() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.json]
    panel.nameFieldStringValue = "permissionpilot-report.json"

    guard panel.runModal() == .OK, let url = panel.url else {
      return
    }

    do {
      try ReportExporter.json(report: store.report).write(to: url)
      exportMessage = "Saved JSON report to \(url.path)."
    } catch {
      exportMessage = "Could not save JSON report: \(error.localizedDescription)"
    }
  }
}

private struct PermissionExplanationCard: View {
  let permission: PermissionDefinition

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

      Button {
        SystemSettingsLinker.open(permission)
      } label: {
        Label("Open System Settings", systemImage: "gear")
      }
      .buttonStyle(.borderedProminent)
    }
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
    }
  }
}

private struct AppPermissionDetail: View {
  let app: InstalledApp

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Permission State")
        .font(.title3.weight(.semibold))

      ForEach(app.permissions) { grant in
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 3) {
            Text(grant.permission.name)
              .font(.headline)
            Text(grant.evidence)
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()
          StatusBadge(status: grant.status)
        }
        Divider()
      }
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

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Background Items")
        .font(.title3.weight(.semibold))

      if items.isEmpty {
        ContentUnavailableView("No Background Items Found", systemImage: "gearshape.2")
      } else {
        ForEach(items.prefix(20)) { item in
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
            }

            Spacer()

            if item.isPotentiallyStale {
              Label("Potentially stale", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.orange)
            }
          }
          Divider()
        }
      }
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
