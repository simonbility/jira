import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

enum SearchError: Error {
    case queryEmpty
}

struct Search: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "Search issues on jira"
    )

    @Option(parsing:.upToNextOption)
    var key: [String] = []

    @Option(parsing:.singleValue)
    var raw: [String] = []
    
    @Option(parsing:.upToNextOption)
    var component: [String] = []
    
    @Option(parsing:.upToNextOption)
    var status: [String] = []
    
    @Option(parsing:.singleValue)
    var sprint: [String] = []
    
    @Flag var currentSprint = false
    @Flag var open = false
    @Flag var closed = false

    var query: JQL {
        var builder = raw

        if !key.isEmpty {
            builder.append("key in (\(key.joined(separator: ", ")))")
        }

        if !sprint.isEmpty {
            builder.append("sprint in (\(sprint.joined(separator: ", ")))")
        }
        if !component.isEmpty {
            builder.append("component in (\(component.joined(separator: ", ")))")
        }
        if !status.isEmpty {
            builder.append("status in (\(status.map { "\"\($0)\"" }.joined(separator: ", ")))")
        }
        if currentSprint {
            builder.append("sprint in openSprints()")
        }
        if open {
            builder.append("status NOT in (\"closed\")")
        }
        if closed {
            builder.append("status in (closed)")
        }

        return JQL(rawValue: builder.joined(separator: " AND "))
    }

    func run() throws {
        
        let terminalController = TerminalController(stream: stdoutStream)
        
        guard !query.rawValue.isEmpty else {
            throw SearchError.queryEmpty
        }
        let results = try api.search(query)
        
        for issue in results.issues.sorted(by: { $0.fields.status < $1.fields.status }) {
            issue.write(to: terminalController)
            terminalController?.endLine()
        }
    }

}
