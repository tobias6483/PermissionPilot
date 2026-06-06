# Privacy & Security Coverage Audit

This audit records the local macOS Privacy & Security coverage used for the current PermissionPilot catalog.

Audit environment:

- macOS 26.4.1, build 25E253.
- Local system resources inspected:
  - `/System/Library/ExtensionKit/Extensions/SecurityPrivacyExtension.appex/Contents/Resources/TCCServiceList.plist`
  - `/System/Library/PreferencePanes/Security.prefPane/Contents/Resources/PrivacyTCCServices.plist`
  - `/System/Library/PreferencePanes/Security.prefPane/Contents/Resources/PrivacyServicesOrder.plist`
  - Local strings from Security Privacy and Security Improvements extensions.
- Private TCC rows were not copied into this document.

## How To Read This Coverage

PermissionPilot scans and reports several different kinds of local privacy/security evidence. They should not be treated as the same thing:

| Evidence type | What PermissionPilot scans | How it appears in the app |
| --- | --- | --- |
| App-scoped TCC permissions | Per-app grants and denials in readable user/system TCC databases. | Shown under installed apps and permission summaries. |
| Global or system-scoped Privacy & Security settings | System Settings categories that apply to the Mac, Apple services, MDM policy, or security posture rather than one app. | Listed in the permission catalog/sidebar and explained as not app-scoped. They are not shown as app grants. |
| Installed app identity | `.app` bundles in `/Applications` and `~/Applications`, plus local `codesign` metadata. | Shown as app inventory, signing identity, Team ID, signing authority, and review-priority evidence. |
| Background execution items | LaunchAgents, LaunchDaemons, Login Items, background tasks, ServiceManagement records, and privileged helper tools. | Shown in the Background Items workflow with kind, path, executable, stale signal, stale reason, and evidence. |
| Local reports | Explicit user-exported Markdown or JSON scan reports. | Exported only when the user chooses an export action. |

The important rule is simple: an app-scoped permission can answer "does this app have this access?" A global/system setting answers "what is this Mac or Apple-service setting?" PermissionPilot keeps those separate to avoid implying that every app has a FileVault, Analytics, Apple Advertising, or Apple Intelligence grant.

## TCC-Backed App Categories

These categories are modeled as app-scoped permission evidence when local TCC databases are readable:

| PermissionPilot category | System Settings category | TCC service evidence |
| --- | --- | --- |
| Location | Location Services | `kTCCServiceLocation` |
| Browser Passkey Access | Browser Passkey Access | `kTCCServiceWebBrowserPublicKeyCredential` |
| Files & Folders | Files & Folders | `kTCCServiceSystemPolicyDesktopFolder`, `kTCCServiceSystemPolicyDocumentsFolder`, `kTCCServiceSystemPolicyDownloadsFolder`, `kTCCServiceSystemPolicyNetworkVolumes`, `kTCCServiceSystemPolicyRemovableVolumes` |
| Photos | Photos | `kTCCServicePhotos`, `kTCCServicePhotosAdd` |
| Full Disk Access | Full Disk Access | `kTCCServiceSystemPolicyAllFiles` |
| Home | Home | `kTCCServiceWillow` |
| Calendars | Calendars | `kTCCServiceCalendar`, `kTCCServiceCalendarFullAccess`, `kTCCServiceCalendarWriteOnly` |
| Contacts | Contacts | `kTCCServiceAddressBook` |
| Media & Apple Music | Media & Apple Music | `kTCCServiceMediaLibrary` |
| Reminders | Reminders | `kTCCServiceReminders` |
| App Management | App Management | `kTCCServiceSystemPolicyAppBundles` |
| Automation / Apple Events | Automation | `kTCCServiceAppleEvents` |
| Motion & Fitness | Motion & Fitness | `kTCCServiceMotion` |
| Bluetooth | Bluetooth | `kTCCServiceBluetoothAlways`, `kTCCServiceBluetoothPeripheral` |
| Focus | Focus | `kTCCServiceFocusStatus` |
| Camera | Camera | `kTCCServiceCamera` |
| Local Network | Local Network | `kTCCServiceLocalNetwork` |
| Microphone | Microphone | `kTCCServiceMicrophone` |
| Screen Recording | Screen & System Audio Recording | `kTCCServiceScreenCapture` |
| System Audio Recording | Screen & System Audio Recording | `kTCCServiceAudioCapture` |
| Keyboard Monitoring | Keyboard Monitoring | `kTCCServiceListenEvent` |
| Remote Desktop | Remote Desktop | `kTCCServiceRemoteDesktop` |
| Speech Recognition | Speech Recognition | `kTCCServiceSpeechRecognition` |
| Accessibility | Accessibility | `kTCCServiceAccessibility` |
| Developer Tools | Developer Tools | `kTCCServiceDeveloperTool` |

Home, Focus, and Remote Desktop are intentionally in this table because the audited macOS System Settings resources expose TCC services for them on macOS 26.4.1. They are not treated as global-only categories.

## Global Or System-Scoped Categories

These categories are included in the catalog for coverage but are not modeled as per-app TCC grants:

| PermissionPilot category | Evidence model |
| --- | --- |
| Sensitive Content Warning | System-level privacy setting. |
| Blocked Contacts | Apple-services list. |
| Analytics & Improvements | Global Apple/app analytics settings and possible management policy. |
| Apple Advertising | Global Apple advertising personalization setting. |
| Apple Intelligence Report | System-level report controls and export flow. |
| FileVault | Security section disk-encryption state. |
| Background Security Improvements | Security Improvements extension and software update policy. |
| Blocked System Software | Security prompts for blocked lower-level software. |
| System-Wide Settings Protection | Administrator authentication requirement for protected settings. |

PermissionPilot reports these as not app-scoped instead of guessing a per-app grant.

These categories are still useful audit coverage. They help users review the Mac's security and Apple-service posture, but they do not belong in each app's "Selected App Permissions" list.

## Scanner Boundaries

- The TCC scanner reads both the user TCC database and the system TCC database when macOS allows access:
  - `~/Library/Application Support/com.apple.TCC/TCC.db`
  - `/Library/Application Support/com.apple.TCC/TCC.db`
- Reads are best-effort, local, and read-only.
- If no TCC database can be read, permission evidence is unavailable.
- If at least one TCC database can be read and no matching app record exists, the app reports `notRecorded`.
- Global/system categories use `SystemPrivacySettingsScanner` and do not infer app-level access.
- App inventory, code-signing evidence, background item evidence, TCC evidence, and global/system setting coverage are separate evidence channels.
