import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

struct Jira: ParsableCommand {

    static var configuration = CommandConfiguration(
        subcommands: [Search.self, Start.self, Current.self]
    )

}

protocol JiraCommand: ParsableCommand {
    var configuration: Configuration { get }
}
