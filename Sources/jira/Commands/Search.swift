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

    @Option(parsing: .upToNextOption)
    var key: [String] = []

    @Option(parsing: .singleValue)
    var raw: [String] = []

    @Option(parsing: .upToNextOption)
    var component: [String] = []

    @Option(parsing: .upToNextOption)
    var status: [String] = []

    @Option(parsing: .singleValue)
    var sprint: [String] = []

    @Flag var currentSprint = false
    @Flag var open = false
    @Flag var closed = false

    var query: JQL {
        var builder = raw

        if !key.isEmpty {
            builder.append("key in (\(commaSeparated: key))")
        }
        if !sprint.isEmpty {
            builder.append("sprint in (\(commaSeparated: sprint))")
        }
        if !component.isEmpty {
            builder.append("component in (\(commaSeparated: component))")
        }
        if !status.isEmpty {
            builder.append("status in (\(commaSeparated: status.map { "\"\($0)\"" }))")
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
        guard !query.rawValue.isEmpty else {
            throw SearchError.queryEmpty
        }
        let results = try api.search(query)

        var grouped: [String: [String: [Issue]]] = [:]

        for issue in results.issues.sorted(by: comparing(\.fields.status)) {
            grouped[issue.componentKey, default: [:]][issue.fields.issuetype.name, default: []]
                .append(issue)
        }

        for (component, componentGroup) in grouped.sorted(by: comparing(\.key)) {
            if grouped.count > 1 {
                terminal.writeLine("# \(component)", inColor: .red)
            }
            for (group, issues) in componentGroup.sorted(by: comparing(\.key)) {
                if componentGroup.count > 1 {
                    terminal.writeLine("## \(group)", inColor: .red)
                }
                for issue in issues {
                    issue.write(to: terminal)
                }

                terminal.endLine()
            }
        }

    }

}
