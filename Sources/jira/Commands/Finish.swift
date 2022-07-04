import AppKit
import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

struct Finish: AsyncParsableCommand {

    static var configuration = CommandConfiguration(
        abstract: "start new feature branch using ticket-number (without prefix like DEV)"
    )

    @Argument var number: String?

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
        
        if let cmd = config.getFixVersionCommand {
            
            let version = try Shell.execute(arguments: [cmd])
            
            try await api.applyIssueUpdate(issue.key) { update in
                update.set(
                    "fixVersions",
                    value: [["name": .string(version)]]
                )
            }
        }
        
        issue.write(to: terminal)
        
        _ = try git.pushCurrentBranch()
        _ = try Shell.execute(arguments: [
            "gh", "pr", "create", "--web",
            "--title",
            "\(issue.key): \(issue.sanitizedSummary)",
        ])
    }

}
