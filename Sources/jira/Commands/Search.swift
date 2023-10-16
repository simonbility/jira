import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

enum SearchError: Error {
    case queryEmpty
}

extension String {
    public func padded(to length: Int, with padCharacter: String = " ") -> String {
        assert(length > 0)

        if count < length {
            return "\(self)\(repeatElement(padCharacter, count: length - count).joined())"
        } else if count > length {
            let prefixLength = (length - 3) / 2
            let prefix = self.prefix(prefixLength)
            let suffixLength = length - (prefix.count + 3)

            return "\(prefix)...\(suffix(suffixLength))"
        } else {
            return self
        }
    }
}

struct Search: AsyncParsableCommand {
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

    @Option(parsing: .upToNextOption)
    var label: [String] = []

    @Option(parsing: .singleValue)
    var sprint: [String] = []

    @Flag var mine = false
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

        if !label.isEmpty {
            builder.append("labels in (\(commaSeparated: label.map { "\"\($0)\"" }))")
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
        if mine {
            builder.append("assignee = currentUser()")
        }

        return JQL(rawValue: builder.joined(separator: " AND "))
    }

    func run() async throws {
        let config = try Configuration.load()
        let api = API(config: config)

        guard !query.rawValue.isEmpty else {
            throw SearchError.queryEmpty
        }
        let results = try await api.search(query)

        var grouped: [String: [String: [Issue]]] = [:]

        for issue in results.issues.sorted(by: comparing(\.fields.status)) {
            grouped[issue.componentKey, default: [:]][issue.fields.issuetype.name, default: []]
                .append(issue)
        }
        
        

        if !terminal.isInteractive {
            let keyWidth = min(100, results.issues.map(\.fields.summary.count).max() ?? 0)

            for issue in results.issues {
                terminal.write(issue.key.padded(to: 10))
                terminal.write(" | ")
                terminal.write(issue.fields.summary.padded(to: keyWidth))
                terminal.write(" | ")
                terminal.write(issue.fields.status.name)
                terminal.endLine()
            }
        } else {
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
}
