import AppKit
import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

struct Finish: ParsableCommand {

    static var configuration = CommandConfiguration(
        abstract: "start new feature branch using ticket-number (without prefix like DEV)"
    )

    @Argument var number: String?

    func run() throws {

        let key =
            try number.map { "DEV-\($0)" }
            ?? git.getIssueKeyFromBranch()

        let issue = try api.find(key: key)
        let text = "- \(issue.key): \(issue.sanitizedSummary)"

        issue.write(to: terminal)

        let cmd = #"""
        gh pr create \
        --web \
        --title "\#(issue.key): \#(issue.sanitizedSummary)" \
        --body \(issue.key)
        """#
        
        terminal.writeLine(cmd, inColor: .cyan)

        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(text, forType: .string)
    }

}
