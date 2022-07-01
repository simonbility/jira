import Foundation

struct Configuration: Codable {
    let baseURL: URL
    let issuePrefix: String
    let defaultBoard: String
    let accountID: String
    let defaultComponent: String?

    static let defaultBaseURL = URL(string: "https://imobility.atlassian.net/rest/")!
    static let defaultIssuePrefix = "DEV"
    static let defaultDefaultBoard = "35"

    static let currentConfigURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(".jira")
    static let userConfigURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".jira")

    static func load() throws -> Configuration {
        let candidates = [
            currentConfigURL,
            userConfigURL,
        ]

        for url in candidates {
            if FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(Configuration.self, from: data)
            }
        }

        throw ConfigFileNotFound()

    }
}

struct ConfigFileNotFound: Error {}
