import Foundation

protocol CodeSignatureScanning {
  func inspectApp(at url: URL) -> CodeSignatureInfo
}

struct CodeSignatureScanner: CodeSignatureScanning {
  func inspectApp(at url: URL) -> CodeSignatureInfo {
    let result = runCodesign(arguments: ["-dv", "--verbose=4", url.path])
    let output = result.output + "\n" + result.error

    guard result.exitCode == 0 else {
      return CodeSignatureInfo(
        isSigned: false,
        teamIdentifier: nil,
        authorities: [],
        identifier: nil,
        evidence: "codesign could not validate this app: \(result.error.trimmingCharacters(in: .whitespacesAndNewlines))"
      )
    }

    return parseCodesignDetails(output)
  }

  func parseCodesignDetails(_ text: String) -> CodeSignatureInfo {
    let lines = text
      .split(separator: "\n")
      .map(String.init)

    let fields = Dictionary(grouping: lines.compactMap(parseKeyValue), by: \.0)
      .mapValues { values in values.map(\.1) }

    let authorities = fields["Authority"] ?? []
    let teamIdentifier = fields["TeamIdentifier"]?.first
    let identifier = fields["Identifier"]?.first

    return CodeSignatureInfo(
      isSigned: true,
      teamIdentifier: teamIdentifier,
      authorities: authorities,
      identifier: identifier,
      evidence: evidence(teamIdentifier: teamIdentifier, authorities: authorities)
    )
  }

  private func parseKeyValue(_ line: String) -> (String, String)? {
    guard let separator = line.firstIndex(of: "=") else {
      return nil
    }

    let key = String(line[..<separator]).trimmingCharacters(in: .whitespaces)
    let value = String(line[line.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
    guard !key.isEmpty, !value.isEmpty else {
      return nil
    }

    return (key, value)
  }

  private func evidence(teamIdentifier: String?, authorities: [String]) -> String {
    if let teamIdentifier, let authority = authorities.first {
      return "Signed by team \(teamIdentifier) with authority \(authority)."
    }

    if let teamIdentifier {
      return "Signed by team \(teamIdentifier)."
    }

    if let authority = authorities.first {
      return "Signed with authority \(authority)."
    }

    return "Code signature exists, but signing identity metadata was limited."
  }

  private func runCodesign(arguments: [String]) -> (exitCode: Int32, output: String, error: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
    process.arguments = arguments

    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      return (1, "", error.localizedDescription)
    }

    let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    return (process.terminationStatus, output, error)
  }
}

