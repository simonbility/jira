import AppKit
import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

struct Start: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "start new feature branch using ticket-number",
        discussion: """
        This will:
        * create a new branch
        * move the ticket into the current sprint
        * assign the ticket to you (or the account-id specified via assign-to)
        """
    )

    @Argument var number: String
    @Argument var assignTo: String?

    func run() async throws {
        let config = try Configuration.load()
        let api = API(config: config)

        var sanitizedNumber = number

        if let url = URL(string: number), url.host == config.baseURL.host {
            sanitizedNumber = url.lastPathComponent
        } else if let key = Issue.findIssueKey(number, wholeMatch: true) {
            sanitizedNumber = key
        } else if number.allSatisfy(\.isNumber) {
            sanitizedNumber = "\(config.issuePrefix)-\(number)"
        }

        precondition(
            Issue.findIssueKey(sanitizedNumber, wholeMatch: true) != nil,
            "\(sanitizedNumber) is not a valid TicketNumber"
        )

        let issue = try await api.find(key: sanitizedNumber)
        let currentSprint = try await api.activeSprint(boardID: config.defaultBoard)

        let accountID: String

        if let assignTo = assignTo {
            accountID = assignTo
        } else {
            accountID = try await api.getCurrentUser().accountId
        }
        try await api.moveIssuesToSprint(sprint: currentSprint, issues: [issue])
        try await api.assignIssue(issue, userID: accountID)

        let branch = issue.branch

        try git.execute(
            "checkout", "-b", "\(branch.type)/\(branch.name)"
        )

        let url = config.baseURL
            .appendingPathComponent("browse")
            .appendingPathComponent(issue.key)

        NSWorkspace.shared.open(url)
    }
}
