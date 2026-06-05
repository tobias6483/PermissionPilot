import Foundation

enum ReportExporter {
  static func markdown(report: PrivacyReport) -> String {
    let formatter = ISO8601DateFormatter()

    var lines: [String] = [
      "# PermissionPilot Privacy Report",
      "",
      "Generated: \(formatter.string(from: report.generatedAt))",
      "",
      "## Apps",
      ""
    ]

    for app in report.apps {
      lines.append("### \(app.name)")
      lines.append("")
      lines.append("- Bundle ID: \(app.bundleIdentifier ?? "unknown")")
      lines.append("- Path: \(app.path)")
      lines.append("- Highest sensitivity: \(app.highestSensitivity.rawValue)")
      lines.append("")
      lines.append("| Permission | Sensitivity | Status | Evidence |")
      lines.append("| --- | --- | --- | --- |")

      for grant in app.permissions {
        lines.append("| \(grant.permission.name) | \(grant.permission.sensitivity.rawValue) | \(grant.status.rawValue) | \(grant.evidence) |")
      }

      lines.append("")
    }

    lines.append("## Background Items")
    lines.append("")

    if report.backgroundItems.isEmpty {
      lines.append("No LaunchAgents or LaunchDaemons were found in scanned locations.")
    } else {
      lines.append("| Kind | Label | Path | Executable | Potentially stale |")
      lines.append("| --- | --- | --- | --- | --- |")

      for item in report.backgroundItems {
        lines.append("| \(item.kind.rawValue) | \(item.label) | \(item.path) | \(item.executable ?? "unknown") | \(item.isPotentiallyStale ? "yes" : "no") |")
      }
    }

    lines.append("")
    lines.append("Note: Unknown permission states mean macOS did not expose that state to this MVP scanner.")

    return lines.joined(separator: "\n")
  }

  static func json(report: PrivacyReport) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    return try encoder.encode(report)
  }
}
