import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

struct Start: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "start new feature branch using ticket-number (without prefix like DEV)"
    )

    @Argument var number: String

    func run() throws {
        let issue = try api.find(key: "DEV-\(number)")
        let branch = issue.branch

        try git.execute(
            "flow", branch.type, "start", branch.name
        )
    }

}
