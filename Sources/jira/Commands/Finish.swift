import AppKit
import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

struct Finish: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        discussion: """
        If no ticket id is provided it will try to extract it from the current branch

        This will:
        * Push the Branch
        * Create a PullRequest
        * For Bugs and Defects ask you to log time
        * Update the FixVersion (if "getFixVersionCommand" is set in your config)
        """
    )

    @Argument var number: String?
    @Option var base: String?

    func run() async throws {
        let config = try Configuration.load()
        let api = API(config: config)

        let key = try git.getIssueKeyFromBranch()

        let issue = try await api.find(key: key)

        let url = config.baseURL
            .appendingPathComponent("browse")
            .appendingPathComponent(issue.key)
        
        terminal.writeLine("Please Log Time")

        NSWorkspace.shared.open(url)
        
        let fixVersion: String?

        if let cmd = config.getFixVersionCommand {
            fixVersion = try Shell.execute(arguments: [cmd])
        } else {
            fixVersion = nil
        }

        if let version = fixVersion {
            try await api.applyIssueUpdate(issue.key) { update in
                update.set(
                    "fixVersions",
                    value: [["name": .string(version)]]
                )
            }
        }

        issue.write(to: terminal)

        var arguments = [
            "gh", "pr", "create", "--web",
            "--title",
            "\(issue.key): \(issue.sanitizedSummary)",
        ]

        if let base = base {
            arguments += ["--base", base]
        } else if let base = try? git.getSourceBranchName() {
            arguments += ["--base", base]
        }

        _ = try git.pushCurrentBranch()
        _ = try Shell.execute(arguments: arguments)
    }
}
