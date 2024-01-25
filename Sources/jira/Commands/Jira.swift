import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

@main
struct Jira: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        subcommands: [
            DumpConfig.self,
            Search.self,
            Start.self,
            Current.self,
            Finish.self,
            Open.self,
        ]
    )
}
