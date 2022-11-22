import ArgumentParser
import Cocoa
import Combine
import Foundation
import TSCBasic
import TSCUtility

struct Open: AsyncParsableCommand {
    enum Errors: String, LocalizedError {
        case noTicketPatternFound = "could not extract ticket from branch"

        var errorDescription: String? { rawValue }
    }

    @Argument var number: String?

    static var configuration = CommandConfiguration(
        abstract: "open jira ticket in browser (if no number passed it will try to get it from the current brunch name)"
    )

    func run() async throws {
        let config = try Configuration.load()
        var sanitizedNumber = number

        if let number = number {
            if let url = URL(string: number), url.host == config.baseURL.host {
                sanitizedNumber = url.lastPathComponent
            } else if let key = Issue.findIssueKey(number, wholeMatch: true) {
                sanitizedNumber = key
            } else if number.allSatisfy(\.isNumber) {
                sanitizedNumber = "\(config.issuePrefix)-\(number)"
            }
        } else {
            sanitizedNumber = try? git.getIssueKeyFromBranch()
        }
            

        precondition(
            Issue.findIssueKey(sanitizedNumber, wholeMatch: true) != nil,
            "\(sanitizedNumber) is not a valid TicketNumber"
        )

        let url = config.baseURL
            .appendingPathComponent("browse")
            .appendingPathComponent(sanitizedNumber)
        // https://imobility.atlassian.net/browse/DEV-14366

        NSWorkspace.shared.open(url)

        // terminal.writeLine(url.absoluteString, inColor: .cyan)
    }
}
