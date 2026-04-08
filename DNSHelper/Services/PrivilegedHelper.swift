import Foundation
import Security

enum PrivilegedHelperError: LocalizedError {
    case scriptFailed(String)
    case userCancelled
    case authorizationFailed
    case setupRequired
    case unknownError

    var errorDescription: String? {
        switch self {
        case .scriptFailed(let msg): return "Command failed: \(msg)"
        case .userCancelled: return "Operation cancelled by user"
        case .authorizationFailed: return "Authorization failed"
        case .setupRequired: return "Setup required. Please complete the initial setup first."
        case .unknownError: return "An unknown error occurred"
        }
    }
}

private let helperToolPath = "/usr/local/bin/dns-helper-tool"
private let sudoersPath = "/etc/sudoers.d/dns-helper"

final class PrivilegedHelper: ObservableObject {
    static let shared = PrivilegedHelper()
    private let logger = AppLogger.shared

    @Published var isSetupComplete: Bool

    private init() {
        isSetupComplete = FileManager.default.fileExists(atPath: helperToolPath)
    }

    // MARK: - One-time Setup

    func setup() throws {
        logger.info("Starting setup...")

        let helperContent = helperScript()
        let sudoersContent = "ALL ALL=(root) NOPASSWD: \(helperToolPath)\n"

        let tempHelper = NSTemporaryDirectory() + "dns-helper-tool-\(UUID().uuidString)"
        let tempSudoers = NSTemporaryDirectory() + "dns-helper-sudoers-\(UUID().uuidString)"

        try helperContent.write(toFile: tempHelper, atomically: true, encoding: .utf8)
        try sudoersContent.write(toFile: tempSudoers, atomically: true, encoding: .utf8)

        let installCommand = """
        mkdir -p /usr/local/bin && \
        cp \(tempHelper) \(helperToolPath) && \
        chmod 755 \(helperToolPath) && \
        chown root:wheel \(helperToolPath) && \
        cp \(tempSudoers) \(sudoersPath) && \
        chmod 440 \(sudoersPath) && \
        chown root:wheel \(sudoersPath) && \
        rm -f \(tempHelper) \(tempSudoers)
        """

        try runOneTimePrivileged(installCommand)

        isSetupComplete = FileManager.default.fileExists(atPath: helperToolPath)

        if isSetupComplete {
            logger.info("Setup completed successfully")
        } else {
            throw PrivilegedHelperError.scriptFailed("Failed to install helper tool")
        }
    }

    func uninstall() throws {
        let command = "rm -f \(helperToolPath) \(sudoersPath)"
        try runOneTimePrivileged(command)
        isSetupComplete = false
        logger.info("Helper tool removed")
    }

    // MARK: - Run Commands (no password after setup)

    func run(_ command: String, args: [String] = []) throws -> String {
        guard isSetupComplete else { throw PrivilegedHelperError.setupRequired }

        let process = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = [helperToolPath, command] + args
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let errorOutput = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            let msg = errorOutput.isEmpty ? "Exit code: \(process.terminationStatus)" : errorOutput
            throw PrivilegedHelperError.scriptFailed(msg)
        }

        return output
    }

    func writeHostsFile(content: String) throws {
        let tempFile = NSTemporaryDirectory() + "dns-helper-hosts-\(UUID().uuidString)"
        try content.write(toFile: tempFile, atomically: true, encoding: .utf8)
        _ = try run("write-hosts", args: [tempFile])
        try? FileManager.default.removeItem(atPath: tempFile)
        logger.info("/etc/hosts updated")
    }

    func setDNS(service: String, servers: [String]) throws {
        _ = try run("set-dns", args: [service] + servers)
    }

    func resetDNS(service: String) throws {
        _ = try run("reset-dns", args: [service])
    }

    func flushDNSCache() throws {
        _ = try run("flush-dns")
        logger.info("DNS cache flushed")
    }

    // MARK: - One-time privileged execution (setup/uninstall only)

    private func runOneTimePrivileged(_ command: String) throws {
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = "do shell script \"\(escaped)\" with administrator privileges"

        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            throw PrivilegedHelperError.unknownError
        }

        appleScript.executeAndReturnError(&error)

        if let error {
            let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? -1
            if errorNumber == -128 {
                throw PrivilegedHelperError.userCancelled
            }
            let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            throw PrivilegedHelperError.scriptFailed(message)
        }
    }

    // MARK: - Embedded helper script

    private func helperScript() -> String {
        """
        #!/bin/bash
        case "$1" in
          write-hosts)
            [ -z "$2" ] && exit 1
            cp "$2" /etc/hosts && chmod 644 /etc/hosts
            ;;
          set-dns)
            shift
            networksetup -setdnsservers "$@"
            ;;
          reset-dns)
            [ -z "$2" ] && exit 1
            networksetup -setdnsservers "$2" empty
            ;;
          flush-dns)
            dscacheutil -flushcache
            killall -HUP mDNSResponder 2>/dev/null
            ;;
          *)
            echo "Unknown command: $1" >&2
            exit 1
            ;;
        esac
        """
    }
}
