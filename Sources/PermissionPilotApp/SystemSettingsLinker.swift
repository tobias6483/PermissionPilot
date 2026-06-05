import AppKit
import Foundation

enum SystemSettingsLinker {
  static func open(_ permission: PermissionDefinition) {
    guard let url = permission.systemSettingsURL else {
      return
    }

    NSWorkspace.shared.open(url)
  }
}

