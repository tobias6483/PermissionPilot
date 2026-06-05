import SwiftUI

@main
struct PermissionPilotApp: App {
  @StateObject private var store = DashboardStore()

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
  }
}

