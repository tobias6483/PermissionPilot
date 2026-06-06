import Foundation

protocol SystemPrivacySettingsScanning {
  func grant(for permission: PermissionDefinition) -> PermissionGrant
}

struct SystemPrivacySettingsScanner: SystemPrivacySettingsScanning {
  func grant(for permission: PermissionDefinition) -> PermissionGrant {
    PermissionGrant(
      permission: permission,
      status: .unavailable,
      evidence: "This Privacy & Security category is global, Apple-service-backed, MDM-managed, or otherwise not exposed as a per-app TCC grant. PermissionPilot records the category for audit coverage but does not infer app-level access from it.",
      evidenceKind: .systemSettingNotAppScoped,
      authorizationColumn: .unavailable
    )
  }
}
