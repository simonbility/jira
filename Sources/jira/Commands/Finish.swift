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

        let key =
            try number.map { "DEV-\($0)" }
            ?? git.getIssueKeyFromBranch()

        let issue = try await api.find(key: key)
        let text = "- \(issue.key): \(issue.sanitizedSummary)"

        issue.write(to: terminal)

        try Shell.execute(arguments: [
            "gh", "pr", "create", "--web",
            "--title", "\"\(issue.key): \(issue.sanitizedSummary)\"",
        ])
    }

}
