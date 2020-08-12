import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility
import AppKit

struct Finish: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "start new feature branch using ticket-number (without prefix like DEV)"
    )

    @Argument var number: String?

    func run() throws {

        let key = try number.map { "DEV-\($0)" }
            ??  git.getIssueKeyFromBranch()
        
        let issue = try api.find(key: key)
        let branch = issue.branch
        
        NSPasteboard.general.setString(
            "- \(issue.key): \(issue.sanitizedSummary)",
            forType: .string
        )
    }

}
