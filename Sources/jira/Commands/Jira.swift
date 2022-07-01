import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

@main
struct Jira: AsyncParsableCommand {

    static var configuration = CommandConfiguration(
        subcommands: [Search.self, Start.self, Current.self, Finish.self, SprintReport.self],
        defaultSubcommand: SprintReport.self
    )

}

