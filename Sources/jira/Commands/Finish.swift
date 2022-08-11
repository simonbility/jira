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

        if issue.isBugOrDefect && issue.loggedTime == 0 {
            let time = terminal.askChecked(
                "Time Spent",
                transform: { $0 }
            )
            try await api.logTime(issue, time: time)
        }
        
        let fixVersion: String?
        
        if let cmd = config.getFixVersionCommand {
            fixVersion = try Shell.execute(arguments: [cmd])
        } else if let defaultVersion = config.defaultFixVersion {
            fixVersion = defaultVersion
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
        }
        _ = try git.pushCurrentBranch()
        _ = try Shell.execute(arguments: arguments)
    }

}
