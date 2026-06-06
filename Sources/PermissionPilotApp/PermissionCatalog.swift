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
      id: "system-audio-recording",
      name: "System Audio Recording",
      sensitivity: .high,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AudioCapture"),
      whyItMatters: "System Audio Recording can expose calls, media playback, alerts, and other audio routed through the Mac.",
      capability: "An app can capture system audio when macOS grants the separate audio-capture service.",
      revokeHint: "Open Privacy & Security, choose Screen & System Audio Recording or System Audio Recording, and disable apps that should not capture Mac audio."
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
      id: "files-and-folders",
      name: "Files & Folders",
      sensitivity: .high,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders"),
      whyItMatters: "Files & Folders access can expose protected Desktop, Documents, Downloads, network volume, or removable volume content.",
      capability: "An app can read or write specific protected file locations that macOS tracks separately from Full Disk Access.",
      revokeHint: "Open Privacy & Security, choose Files & Folders, and disable folder access that no longer matches how you use the app."
    ),
    PermissionDefinition(
      id: "app-management",
      name: "App Management",
      sensitivity: .high,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles"),
      whyItMatters: "App Management access can allow one app to modify or manage other installed apps.",
      capability: "An app may update, delete, or alter app bundles in locations macOS protects.",
      revokeHint: "Open Privacy & Security, choose App Management, and remove access for apps that should not manage other apps."
    ),
    PermissionDefinition(
      id: "keyboard-monitoring",
      name: "Keyboard Monitoring",
      sensitivity: .high,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"),
      whyItMatters: "Keyboard Monitoring access can expose typed text, shortcuts, and other input events.",
      capability: "An app can monitor keyboard input outside its own windows when macOS grants access.",
      revokeHint: "Open Privacy & Security, choose Keyboard Monitoring, and disable apps that should not observe keyboard input."
    ),
    PermissionDefinition(
      id: "developer-tools",
      name: "Developer Tools",
      sensitivity: .high,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_DevTools"),
      whyItMatters: "Developer Tools access can allow debugging or control of development processes and other local tools.",
      capability: "An app may use developer-oriented privileges that are powerful in build, debug, and automation workflows.",
      revokeHint: "Open Privacy & Security, choose Developer Tools, and keep access limited to tools you actively use and recognize."
    ),
    PermissionDefinition(
      id: "remote-desktop",
      name: "Remote Desktop",
      sensitivity: .high,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_RemoteDesktop"),
      whyItMatters: "Remote Desktop access can allow remote observation or control workflows that affect the whole Mac.",
      capability: "An app can participate in remote desktop control when macOS grants the service.",
      revokeHint: "Open Privacy & Security, choose Remote Desktop, and disable apps or tools that should not provide remote access."
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
      id: "motion-fitness",
      name: "Motion & Fitness",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Motion"),
      whyItMatters: "Motion & Fitness access can expose activity and movement-related context.",
      capability: "An app can read motion or fitness data when macOS grants access.",
      revokeHint: "Open Privacy & Security, choose Motion & Fitness, and disable apps that no longer need activity data."
    ),
    PermissionDefinition(
      id: "home",
      name: "Home",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_HomeKit"),
      whyItMatters: "Home access can expose smart-home devices, rooms, scenes, and household automation context.",
      capability: "An app can interact with HomeKit data and accessories when macOS grants access.",
      revokeHint: "Open Privacy & Security, choose Home, and remove apps that should not access Home data."
    ),
    PermissionDefinition(
      id: "photos",
      name: "Photos",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos"),
      whyItMatters: "Photos access can expose personal images, videos, metadata, and memories.",
      capability: "An app can read or add items to the Photos library depending on the access macOS grants.",
      revokeHint: "Open Privacy & Security, choose Photos, and limit apps to the photo-library access they still need."
    ),
    PermissionDefinition(
      id: "contacts",
      name: "Contacts",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts"),
      whyItMatters: "Contacts access can expose names, phone numbers, email addresses, addresses, and relationship context.",
      capability: "An app can read or update contacts when macOS grants access.",
      revokeHint: "Open Privacy & Security, choose Contacts, and turn off access for apps that should not use your address book."
    ),
    PermissionDefinition(
      id: "calendars",
      name: "Calendars",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"),
      whyItMatters: "Calendar access can reveal meetings, routines, locations, invitees, and private plans.",
      capability: "An app can read or modify calendar data depending on the access macOS grants.",
      revokeHint: "Open Privacy & Security, choose Calendars, and remove access that no longer supports a real workflow."
    ),
    PermissionDefinition(
      id: "reminders",
      name: "Reminders",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"),
      whyItMatters: "Reminders access can expose tasks, routines, errands, and time-sensitive personal context.",
      capability: "An app can read or modify reminders when macOS grants access.",
      revokeHint: "Open Privacy & Security, choose Reminders, and disable access for apps that should not manage reminders."
    ),
    PermissionDefinition(
      id: "media-library",
      name: "Media & Apple Music",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Media"),
      whyItMatters: "Media library access can reveal music, video, and listening-library context.",
      capability: "An app can access local media-library information when macOS grants access.",
      revokeHint: "Open Privacy & Security, choose Media & Apple Music, and remove apps that should not access media-library data."
    ),
    PermissionDefinition(
      id: "speech-recognition",
      name: "Speech Recognition",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition"),
      whyItMatters: "Speech Recognition access can process spoken words and dictated content.",
      capability: "An app can use speech-recognition services for audio it receives or records.",
      revokeHint: "Open Privacy & Security, choose Speech Recognition, and disable apps that no longer need speech features."
    ),
    PermissionDefinition(
      id: "focus",
      name: "Focus",
      sensitivity: .low,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Focus"),
      whyItMatters: "Focus status access can reveal whether notifications are silenced or a user is in a focused mode.",
      capability: "An app can read Focus status when macOS grants access.",
      revokeHint: "Open Privacy & Security, choose Focus, and disable access for apps that do not need status awareness."
    ),
    PermissionDefinition(
      id: "local-network",
      name: "Local Network",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocalNetwork"),
      whyItMatters: "Local Network access can reveal and interact with devices and services on nearby networks.",
      capability: "An app can discover or communicate with local network devices when macOS grants access.",
      revokeHint: "Open Privacy & Security, choose Local Network, and disable access for apps that should not talk to local devices."
    ),
    PermissionDefinition(
      id: "bluetooth",
      name: "Bluetooth",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth"),
      whyItMatters: "Bluetooth access can reveal nearby devices and allow communication with accessories.",
      capability: "An app can discover or communicate with Bluetooth devices when macOS grants access.",
      revokeHint: "Open Privacy & Security, choose Bluetooth, and disable apps that should not use nearby devices."
    ),
    PermissionDefinition(
      id: "browser-passkey-access",
      name: "Browser Passkey Access",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_PasskeyAccess"),
      whyItMatters: "Browser passkey access can affect which browsers can use public-key credential workflows.",
      capability: "A browser can request passkey/public-key credential access when macOS grants the service.",
      revokeHint: "Open Privacy & Security, choose Browser Passkey Access, and review browsers that can use passkey access."
    ),
    PermissionDefinition(
      id: "automation",
      name: "Automation / Apple Events",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"),
      whyItMatters: "Automation access can let one app control another app or request data from it.",
      capability: "An app can send Apple Events to approved target apps.",
      revokeHint: "Open Privacy & Security, choose Automation, and remove unneeded app-to-app control paths."
    ),
    PermissionDefinition(
      id: "sensitive-content-warning",
      name: "Sensitive Content Warning",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_NudityDetection"),
      whyItMatters: "Sensitive Content Warning is a system-level safety feature rather than an app grant.",
      capability: "macOS may warn before showing sensitive images or media in supported Apple experiences.",
      revokeHint: "Open Privacy & Security, choose Sensitive Content Warning, and review the system-level setting.",
      evidenceSource: .systemSetting
    ),
    PermissionDefinition(
      id: "blocked-contacts",
      name: "Blocked Contacts",
      sensitivity: .low,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Blocklist"),
      whyItMatters: "Blocked Contacts is an Apple-services list, not a per-app permission grant.",
      capability: "macOS and Apple apps can use the blocked contacts list to limit communication from selected people.",
      revokeHint: "Open Privacy & Security, choose Blocked Contacts, and review the system-level list.",
      evidenceSource: .systemSetting
    ),
    PermissionDefinition(
      id: "analytics-improvements",
      name: "Analytics & Improvements",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Analytics"),
      whyItMatters: "Analytics settings control whether diagnostic and improvement data is shared with Apple or app developers.",
      capability: "The system can share analytics according to the global settings and management policy.",
      revokeHint: "Open Privacy & Security, choose Analytics & Improvements, and review the global sharing options.",
      evidenceSource: .systemSetting
    ),
    PermissionDefinition(
      id: "apple-advertising",
      name: "Apple Advertising",
      sensitivity: .low,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Advertising"),
      whyItMatters: "Apple Advertising controls personalization for Apple advertising surfaces.",
      capability: "Apple services can personalize ads according to the global setting.",
      revokeHint: "Open Privacy & Security, choose Apple Advertising, and review personalized ads.",
      evidenceSource: .systemSetting
    ),
    PermissionDefinition(
      id: "apple-intelligence-report",
      name: "Apple Intelligence Report",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AppleIntelligenceReport"),
      whyItMatters: "Apple Intelligence Report is a system-level report about Apple Intelligence requests and privacy behavior.",
      capability: "macOS can generate and export Apple Intelligence report data according to the system setting.",
      revokeHint: "Open Privacy & Security, choose Apple Intelligence Report, and review the report duration and export controls.",
      evidenceSource: .systemSetting
    ),
    PermissionDefinition(
      id: "filevault",
      name: "FileVault",
      sensitivity: .high,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?FileVault"),
      whyItMatters: "FileVault protects data on the startup disk with encryption.",
      capability: "macOS can require disk unlock credentials before data on the startup volume is available.",
      revokeHint: "Open Privacy & Security, choose FileVault, and review disk encryption status and recovery options.",
      evidenceSource: .systemSetting
    ),
    PermissionDefinition(
      id: "background-security-improvements",
      name: "Background Security Improvements",
      sensitivity: .high,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.Security-Settings.extension"),
      whyItMatters: "Background Security Improvements can add system protections between full macOS updates.",
      capability: "macOS can install or remove background security improvements according to update policy and MDM management.",
      revokeHint: "Open Privacy & Security, review the Security section, and keep Background Security Improvements enabled unless you have a documented compatibility reason.",
      evidenceSource: .systemSetting
    ),
    PermissionDefinition(
      id: "blocked-system-software",
      name: "Blocked System Software",
      sensitivity: .high,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?General"),
      whyItMatters: "Blocked system software entries can indicate kernel/system extensions macOS prevented from loading.",
      capability: "macOS can block lower-level software from loading until an administrator reviews it.",
      revokeHint: "Open Privacy & Security, review blocked software prompts, and approve only software you recognize and intentionally installed.",
      evidenceSource: .systemSetting
    ),
    PermissionDefinition(
      id: "system-wide-settings-password",
      name: "System-Wide Settings Protection",
      sensitivity: .medium,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Advanced"),
      whyItMatters: "System-wide settings protection controls whether administrator authentication is required before changing protected settings.",
      capability: "macOS can require an administrator password before unlocking system-wide settings panes.",
      revokeHint: "Open Privacy & Security, review the Security section, and keep administrative authentication requirements aligned with your threat model.",
      evidenceSource: .systemSetting
    )
  ]
}
