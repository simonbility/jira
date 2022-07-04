import ArgumentParser
import Foundation

struct Init: AsyncParsableCommand {

    @Option var baseURL: String = Configuration.defaultBaseURL.absoluteString
    @Option var issuePrefix: String = Configuration.defaultIssuePrefix
    @Option var defaultBoard: String = Configuration.defaultDefaultBoard
    @Option var defaultComponent: String?
    @Option(
        help: ArgumentHelp("path to a script providing the current fix-version"),
        completion: .file()
    )
    var getFixVersionCommand: String?
    
    @Flag var global = false

    func run() async throws {
        guard ProcessInfo.processInfo.environment["JIRA_CREDENTIALS"] != nil else {
            throw CleanExit.message("Please set JIRA_CREDENTIALS environment variable")
        }
        
        if !Shell.isInstalled("gh") {
            terminal.writeLine("gh is not installed", inColor: .yellow)
            terminal.writeLine("This is needed to create PRs")
            terminal.writeLine("Install with 'brew install gh' (https://cli.github.com)")
        }
        
        if !Shell.isInstalled("figlet") {
            terminal.writeLine("figlet is not installed", inColor: .yellow)
            terminal.writeLine("This is used to create the AsciArt in SprintReports")
            terminal.writeLine("Install with 'brew install figlet' (http://www.figlet.org)")
        }
        
        let baseURL = try URL.parse(string: baseURL)
        
        let config = Configuration(
            baseURL: baseURL,
            issuePrefix: issuePrefix,
            defaultBoard: defaultBoard,
            defaultComponent: defaultComponent,
            getFixVersionCommand: nil
        )
        
        let location = global ? Configuration.userConfigURL : Configuration.currentConfigURL
       
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        try encoder.encode(config).write(
            to: location,
            options: [ .withoutOverwriting]
        )
        
        terminal.writeLine(
            "Config file created at \(location.relativePath)", inColor: .green
        )
    }
    
}


extension URL {
    static func parse(string: String) throws -> URL {
        guard let url = URL(string: string) else {
            throw JiraError.custom("Could not parse \(string)")
        }
        return url
    }
}
