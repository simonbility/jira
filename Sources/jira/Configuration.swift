import ArgumentParser
import Foundation

struct Configuration: Codable {
    let baseURL: URL
    let issuePrefix: String
    let getFixVersionCommand: String?
    let teamID: String?

    static let defaultBaseURL = URL(string: "https://imobility.atlassian.net/")!
    static let defaultIssuePrefix = "IMOB"

    static let currentConfigURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(".jira")
    static let userConfigURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".jira")

    static func load() throws -> Configuration {
        // sorted from generic to specific
        let candidates = [
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".jira-config"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(".jira-config"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(".jira-config-user"), // should be placed in gitignore
        ]

        let configURLs = candidates.filter { url in
            var isDirectory: ObjCBool = false

            let exists = FileManager.default
                .fileExists(atPath: url.path, isDirectory: &isDirectory)

            return exists && !isDirectory.boolValue
        }

        if configURLs.isEmpty {
            throw CleanExit.message("No config file found run 'jira init' to create one")
        }

        let mergedConfigs: [String: JSON] = try configURLs.reduce(into: [:]) { partialResult, url in
            let config = try JSONDecoder().decode([String: JSON].self, from: Data(contentsOf: url))

            partialResult.merge(config, uniquingKeysWith: { _, new in new })
        }

        let mergedData = try JSONEncoder().encode(mergedConfigs)

        return try JSONDecoder().decode(Configuration.self, from: mergedData)
    }
}
