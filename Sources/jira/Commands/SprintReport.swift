import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

struct SprintReport: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Generates a report about all Tickets in Sprint"
    )

    @Flag(inversion: .prefixedNo) var includeTickets = true
    @Flag(inversion: .prefixedNo) var includeTestTickets = false
    @Option var sprint: Int?

    func run() async throws {
        let config = try Configuration.load()
        let api = API(config: config)
        let sprint = try await api.activeSprint(boardID: config.defaultBoard, sprintID: sprint)

        let results = try await api.search(
            JQL {
                "sprint in (\(sprint.id))"
                "issuetype in (Story,Operations,Improvement)"
                "component in (ios,android,backend)"
            }
        )

        let epics = results.issues.compactMap {
            $0.fields.parent
        }
        .filter {
            $0.isEpic
        }
        .distinct(by: \.key)

        let keys = epics.map { $0.key }.joined(separator: ",")

        let integrationTests = try await api.search(
            JQL {
                "labels in (dev-qa-task)"
                "parent in (\(keys))"
            }
        )

        var components = URLComponents(
            string: "https://imobility.atlassian.net/jira/software/c/projects/DEV/boards/2/timeline"
        )!

        components.queryItems = [
            URLQueryItem(name: "issueParent", value: epics.map { $0.id }.joined(separator: ",")),
            URLQueryItem(name: "issueType", value: "4,10100,10522,10001"),
            URLQueryItem(name: "hideVersionHeader", value: "true"),
            URLQueryItem(name: "hideDependencies", value: "true"),
            URLQueryItem(name: "timeline", value: "WEEKS"),
            URLQueryItem(name: "epic", value: "COMPLETE12M"),
        ]

        printIntro(sprint: sprint, timelineURL: components.url!)

        if includeTickets {
            let grouped = Dictionary(
                grouping: results.issues.distinct(by: \.key),
                by: {
                    $0.fields.parent?.keyAndSummary ?? "no-epic"
                }
            ).sorted { $0.key < $1.key }

            for group in grouped {
                terminal.write("### ")
                terminal.write(group.key)
                terminal.endLine()
                for issue in group.value {
                    terminal.write("* ")
                    terminal.writeLine(issue.keyAndSummary)
                }
                terminal.endLine()
            }
        }

        if includeTestTickets {
            terminal.write("## IntegrationTestTickets")
            terminal.endLine()
            for issue in integrationTests.issues {
                terminal.writeLine("https://imobility.atlassian.net/browse/\(issue.key)")
//                terminal.writeLine(issue.keyAndSummary)
            }
            terminal.endLine()
        }
    }

    func printIntro(sprint: Sprint, timelineURL: Foundation.URL) {
        terminal.writeLine("## \(sprint.sanitizedName)")
        terminal.endLine()
        terminal.writeLine(
            "[BurnupChart](https://imobility.atlassian.net/jira/software/c/projects/DEV/boards/35/reports/burnup-chart?sprint=\(sprint.id))",
            inColor: .cyan
        )
        terminal.writeLine("[TimeLine](\(timelineURL.absoluteString))", inColor: .cyan)
        terminal.endLine()
    }
}

extension Array {
    mutating func extract(
        where predicate: (Element) -> Bool
    ) -> [Element] {
        let result = filter(predicate)
        removeAll(where: predicate)
        return result
    }

    func distinct<Key: Hashable>(
        by key: (Element) -> Key
    ) -> [Element] {
        var seen: Set<Key> = []

        return filter { seen.insert(key($0)).inserted }
    }
}
