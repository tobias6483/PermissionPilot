import SwiftUI

@main
struct PermissionPilotApp: App {
  @StateObject private var store = DashboardStore()
  @AppStorage("developerModeEnabled") private var developerModeEnabled = false

  var body: some Scene {
    WindowGroup {
      DashboardView()
        .environmentObject(store)
        .task {
          await store.refresh()
        }
    }
    .windowStyle(.titleBar)
    .commands {
      CommandGroup(after: .appInfo) {
        Button("Refresh Scan") {
          Task {
            await store.refresh()
          }
        }
        .keyboardShortcut("r", modifiers: [.command])
      }
    }

    Settings {
      SettingsView(developerModeEnabled: $developerModeEnabled)
    }
  }
}

private struct SettingsView: View {
  @Binding var developerModeEnabled: Bool

  var body: some View {
    Form {
      Toggle("Developer Mode", isOn: $developerModeEnabled)
      Text("Shows local QA controls for validating System Settings links. This does not modify permissions or macOS settings.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(20)
    .frame(width: 420)
  }
}
