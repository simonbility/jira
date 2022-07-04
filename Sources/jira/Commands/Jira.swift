import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

@main
struct Jira: AsyncParsableCommand {

    static var configuration = CommandConfiguration(
        subcommands: [
            Init.self,
            Search.self,
            Start.self,
            Current.self,
            Finish.self,
            SprintReport.self,
        ]
    )

}
