import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

struct SprintReport: ParsableCommand {

    static var configuration = CommandConfiguration(
        abstract: "Generates a report about all Tickets in Sprint"
    )

    func run() throws {
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

        printGroup(name: "Backend", issues: backendTickets)
        printGroup(name: "Clients", allIssues: clientTickets)
        printGroup(name: "iOS", issues: iOSTickets)
        printGroup(name: "Android", issues: androidTickets)

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

        for (issueType, groupedIssues) in groups {
            terminal.writeLine("## \(name) - \(issueType.name)", inColor: .red)

            for aissues in groupedIssues {
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

                terminal.endLine()
            }

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
