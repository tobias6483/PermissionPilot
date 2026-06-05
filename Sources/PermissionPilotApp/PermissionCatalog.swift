import Foundation

enum PermissionCatalog {
  static let all: [PermissionDefinition] = [
    PermissionDefinition(
      id: "screen-recording",
      name: "Screen Recording",
      sensitivity: .high,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"),
      whyItMatters: "Screen Recording can expose windows, documents, messages, browser tabs, and other visible local context.",
      capability: "An app can capture the screen or observe visual desktop state while it is running.",
      revokeHint: "Open Privacy & Security, choose Screen Recording, and turn off access for apps you do not recognize or no longer use."
    ),
    PermissionDefinition(
      id: "accessibility",
      name: "Accessibility",
      sensitivity: .high,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"),
      whyItMatters: "Accessibility access can let an app observe and control other apps through UI automation.",
      capability: "An app may click buttons, read UI labels, move focus, type, or automate workflows in other apps.",
      revokeHint: "Open Privacy & Security, choose Accessibility, and disable apps that do not need automation privileges."
    ),
    PermissionDefinition(
      id: "full-disk-access",
      name: "Full Disk Access",
      sensitivity: .high,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"),
      whyItMatters: "Full Disk Access can expose protected app data, backups, mail, messages, and user documents.",
      capability: "An app can read areas of the file system that macOS normally protects from ordinary apps.",
      revokeHint: "Open Privacy & Security, choose Full Disk Access, and remove apps that no longer need broad file access."
    ),
    PermissionDefinition(
      id: "microphone",
      name: "Microphone",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"),
      whyItMatters: "Microphone access can capture conversations, calls, and ambient audio.",
      capability: "An app can receive audio input while permission is active.",
      revokeHint: "Open Privacy & Security, choose Microphone, and disable access for apps that should not record audio."
    ),
    PermissionDefinition(
      id: "camera",
      name: "Camera",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"),
      whyItMatters: "Camera access can expose the user and their surroundings.",
      capability: "An app can receive video input while permission is active.",
      revokeHint: "Open Privacy & Security, choose Camera, and disable access for apps that should not capture video."
    ),
    PermissionDefinition(
      id: "location",
      name: "Location",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"),
      whyItMatters: "Location access can reveal where the Mac is used and movement patterns over time.",
      capability: "An app can request location data when macOS grants it.",
      revokeHint: "Open Privacy & Security, choose Location Services, and review apps with location access."
    ),
    PermissionDefinition(
      id: "automation",
      name: "Automation / Apple Events",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"),
      whyItMatters: "Automation access can let one app control another app or request data from it.",
      capability: "An app can send Apple Events to approved target apps.",
      revokeHint: "Open Privacy & Security, choose Automation, and remove unneeded app-to-app control paths."
    )
  ]
}

