import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

struct SprintReport: ParsableCommand {

    static var configuration = CommandConfiguration(
        abstract: "Generates a report about all Tickets in Sprint"
    )

    private static let maxPageSize = 10

    func run() throws {

        let sprint = try api.activeSprint(boardID: "35")

        let results = try api.search(
            JQL {
                "sprint in openSprints()"
                "issuetype in (Bug,Defect,Story,Operations,Improvement)"
                "component in (ios,android,backend)"
            }
        )

        var groups: [String: [Issue]] = [:]

        for issue in results.issues.sorted(by: comparing(\.sanitizedSummary)) {
            for component in issue.fields.components {
                groups[component.name.lowercased(), default: []].append(issue)
            }
        }

        var iOSTickets = groups["ios", default: []].distinct(by: \.key)
        var androidTickets = groups["android", default: []].distinct(by: \.key)
        let backendTickets = groups["backend", default: []].distinct(by: \.key)
        let clientTickets: [[Issue]]

        let iosTicketNames = Set(iOSTickets.map(\.sanitizedSummary))
        let androidTicketNames = Set(androidTickets.map(\.sanitizedSummary))

        let clientTicketNames = iosTicketNames.intersection(androidTicketNames)

        clientTickets = zip(
            iOSTickets.extract {
                clientTicketNames.contains($0.sanitizedSummary)
            },
            androidTickets.extract {
                clientTicketNames.contains($0.sanitizedSummary)
            }
        ).map { [$0, $1] }

        printIntro(sprint: sprint)
        printGroup(name: "Backend", issues: backendTickets)
        printGroup(name: "Clients", allIssues: clientTickets)
        printGroup(name: "iOS", issues: iOSTickets)
        printGroup(name: "Android", issues: androidTickets)

    }
    
    func printIntro(sprint: Sprint) {
        terminal.writeLine("---")
        terminal.writeLine("author: \(sprint.sanitizedName)")
        terminal.writeLine("---")
        
        terminal.write(asciArt.getAsMarkdown(sprint.sanitizedName))
        terminal.endLine()
        terminal.writeLine("https://imobility.atlassian.net/jira/software/c/projects/DEV/boards/35/reports/burnup-chart?sprint=\(sprint.id)")
        
        terminal.writeLine("---")

    }

    func printGroup(name: String, issues: [Issue]) {
        printGroup(name: name, allIssues: issues.map { [$0] })
    }

    func printGroup(name: String, allIssues: [[Issue]]) {
        let groups = Dictionary(
            grouping: allIssues,
            by: \.first!.fields.issuetype
        )
        .sorted(
            by: comparing(\.key)
        )

        terminal.write(asciArt.getAsMarkdown(name))
        terminal.endLine()
        terminal.write("---")
        terminal.endLine()

        for (issueType, groupedIssues) in groups {
            terminal.writeLine("## \(name) - \(issueType.name)", inColor: .red)

            var counter = 0

            for aissues in groupedIssues {
                if counter > Self.maxPageSize {
                    counter = 0
                    terminal.endLine()
                    terminal.writeLine("---")
                    terminal.endLine()

                    terminal.writeLine("## \(name) - \(issueType.name)", inColor: .red)
                }

                let issues = aissues.distinct(by: \.key)
                let issue = issues.first!

                terminal.write("* ")
                terminal.write(issue.sanitizedSummary)
                terminal.write(" ")

                let open = issues.filter { !$0.isClosed }

                if !open.isEmpty {
                    terminal.write("(")
                    if open.count == 1 {
                        terminal.write(
                            issue.fields.status.name,
                            inColor: issue.fields.status.terminalColor
                        )
                    } else {

                        let componentToStatus = issues.flatMap { iss in
                            iss.fields.components.map { ($0, iss.fields.status) }
                        }

                        for (index, (component, status)) in componentToStatus.enumerated() {
                            if index > 0 {
                                terminal.write(", ")
                            }

                            terminal.write(
                                "\(component.name): \(status.name)",
                                inColor: issue.fields.status.terminalColor
                            )
                        }

                    }

                    terminal.write(")")
                }

                counter += 1

                terminal.endLine()

            }

            terminal.endLine()
            terminal.writeLine("---")
            terminal.endLine()
        }
    }

}

extension Array {
    mutating func extract(
        where predicate: (Element) -> Bool
    ) -> [Element] {
        let result = self.filter(predicate)
        self.removeAll(where: predicate)
        return result
    }

    func distinct<Key: Hashable>(
        by key: (Element) -> Key
    ) -> [Element] {
        var seen: Set<Key> = []

        return self.filter { seen.insert(key($0)).inserted }
    }

}
