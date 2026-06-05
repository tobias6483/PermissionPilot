import Foundation

enum ReportExporter {
  static func markdown(report: PrivacyReport) -> String {
    let formatter = ISO8601DateFormatter()
    let summary = PrivacyReportSummary(report: report)

    var lines: [String] = [
      "# PermissionPilot Privacy Report",
      "",
      "Generated: \(formatter.string(from: report.generatedAt))",
      "",
      "## Scan Summary",
      "",
      "- Apps scanned: \(summary.appCount)",
      "- Signed apps: \(summary.signedAppCount)",
      "- Unsigned or unknown apps: \(summary.unsignedOrUnknownAppCount)",
      "- High-sensitivity grants: \(summary.highSensitivityGrantCount)",
      "- Background items: \(summary.backgroundItemCount)",
      "- Potentially stale background items: \(summary.potentiallyStaleBackgroundItemCount)",
      "",
      "## Permission Summary",
      "",
      "| Permission | Sensitivity | Granted | Denied | Unknown |",
      "| --- | --- | --- | --- | --- |"
    ]

    for permissionSummary in summary.permissionSummaries {
      lines.append("| \(permissionSummary.name) | \(permissionSummary.sensitivity.rawValue) | \(permissionSummary.granted) | \(permissionSummary.denied) | \(permissionSummary.unknown) |")
    }

    lines += [
      "",
      "## Apps",
      ""
    ]

    for app in report.apps {
      lines.append("### \(app.name)")
      lines.append("")
      lines.append("- Bundle ID: \(app.bundleIdentifier ?? "unknown")")
      lines.append("- Path: \(app.path)")
      lines.append("- Code signature: \(app.signingInfo.isSigned ? "signed" : "unsigned or unknown")")
      lines.append("- Team ID: \(app.signingInfo.teamIdentifier ?? "unknown")")
      lines.append("- Signing authority: \(app.signingInfo.authorities.joined(separator: " -> ").nilIfEmpty ?? "unknown")")
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
    return try encoder.encode(ExportedPrivacyReport(summary: PrivacyReportSummary(report: report), report: report))
  }
}

private struct ExportedPrivacyReport: Codable {
  let summary: PrivacyReportSummary
  let report: PrivacyReport
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
