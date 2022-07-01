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
        let config = try Configuration.load()
        let api = API(config: config)
        
        var sanitizedNumber = number
        
        if let key = Issue.findIssueKey(number, wholeMatch: true) {
            sanitizedNumber = key
        } else if number.allSatisfy(\.isNumber) {
            sanitizedNumber = "\(config.issuePrefix)-\(number)"
        }
        
        
        let issue = try await api.find(key: sanitizedNumber)
        let currentSprint = try await api.activeSprint(boardID: config.defaultBoard)
        
        try await api.moveIssuesToSprint(sprint: currentSprint, issues: [issue])
        try await api.assignIssue(issue, userID: config.accountID)
        
        let branch = issue.branch
        let base = try git.getCurrentBranch()

        try git.execute(
            "flow", branch.type, "start", branch.name, base
        )
    }

}
