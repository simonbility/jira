import ArgumentParser
import Foundation

struct Init: AsyncParsableCommand {
    
    @Option var baseURL: String?
    @Option var issuePrefix: String?
    @Option var defaultBoard: String?
    @Option var userName: String?
    @Option var defaultComponent: String?
    
    @Flag var global = false

    func run() async throws {
        guard ProcessInfo.processInfo.environment["JIRA_CREDENTIALS"] != nil else {
            throw ValidationError("Please set JIRA_CREDENTIALS environment variable")
        }
        
        let baseURL = terminal.askChecked(
            "API-BaseURL default: \(Configuration.defaultBaseURL.absoluteString))",
            default: Configuration.defaultBaseURL,
            transform: URL.parse(string:)
        )
        let issuePrefix = terminal.askChecked(
            "IssueKey default: \(Configuration.defaultIssuePrefix)",
            default: Configuration.defaultIssuePrefix,
            transform: { $0 }
        )
        let defaultComponent: String? = terminal.askChecked(
            "Default Component",
            default: nil,
            transform: { $0.isEmpty ? nil : $0 }
        )
        let defaultBoard = terminal.askChecked(
            "DefaultBoard default: \(Configuration.defaultDefaultBoard)",
            default: Configuration.defaultDefaultBoard,
            transform: { $0 }
        )

        let tempAPI = API(base: baseURL)
        let user = try await tempAPI.getCurrentUser()
        
        let config = Configuration(
            baseURL: baseURL,
            issuePrefix: issuePrefix,
            defaultBoard: defaultBoard,
            accountID: user.accountId,
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
