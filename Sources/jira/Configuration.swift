import ArgumentParser
import Foundation
import Yams

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
                .appendingPathComponent(".jira/config.yml"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(".jira/config.yml"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(".jira/private.yml"), // should be placed in gitignore
        ]

        let configURLs = candidates.filter { url in
            var isDirectory: ObjCBool = false

            let exists = FileManager.default
                .fileExists(atPath: url.path, isDirectory: &isDirectory)

            return exists && !isDirectory.boolValue
        }

        if configURLs.isEmpty {
            throw CleanExit.message("""
            No config file found at
            \(candidates.map { $0.path }.joined(separator: "\n"))
            
            run 'jira init' to create one
            """)
        }
        
        let encoder = YAMLEncoder()
        let decoder = YAMLDecoder()

        let mergedConfigs: [String: JSON] = try configURLs.reduce(into: [:]) { partialResult, url in
            terminal.writeLine("Using config at \(url.path)", inColor: .green, debug: true)
            
            let config = try decoder.decode([String: JSON].self, from: Data(contentsOf: url))

            partialResult.merge(config, uniquingKeysWith: { _, new in new })
        }

        let mergedData = try encoder.encode(mergedConfigs)

        return try decoder.decode(Configuration.self, from: mergedData)
    }
}
