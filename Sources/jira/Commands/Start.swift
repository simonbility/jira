import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

struct Start: AsyncParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "start new feature branch using ticket-number (without prefix like DEV)"
    )

    @Argument var number: String

    func run() async throws {
        let issue = try await api.find(key: "DEV-\(number)")
        let branch = issue.branch
        let base = try git.getCurrentBranch()

        try git.execute(
            "flow", branch.type, "start", branch.name, base
        )
    }

}
