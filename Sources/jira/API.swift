//
//  File.swift
//
//
//  Created by Simon Anreiter on 23.05.20.
//

import ArgumentParser
import Combine
import Foundation
import TSCBasic

enum JiraError: Error {
    case underlying(Error)
    case multipleIssuesFound([Issue])
    case notFound
    case custom(String)
}

protocol JiraAPI {
    func search(_ search: JQL) async throws -> SearchResults
    func find(key: String) async throws -> Issue
}

enum FindIssueError: Error {
    case ambiguous([Issue])
    case notFound
    case underlying(Error)
}

class API: JiraAPI {

    init(credentials: String? = ProcessInfo.processInfo.environment["JIRA_CREDENTIALS"]) {
        self.credentials = credentials
    }

    let session = URLSession.shared
    let base = URL(string: "https://imobility.atlassian.net/rest/")!
    let credentials: String?
    var cancellables: [AnyCancellable] = []

    func search(_ search: JQL) async throws -> SearchResults {
        return try await _search(search)
    }

    func activeSprint(boardID: String) async throws -> Sprint {
        
        return try await request(
            as: SprintSearchResults.self,
            path: "agile/1.0/board/\(boardID)/sprint",
            query: ["state":"active"]
        ).values[0]
    }

    func find(key: String) async throws -> Issue {

        let jql = JQL(rawValue: "key = \(key)")

        let results = try await self._search(jql)

        switch results.issues.count {
        case 1: return results.issues[0]
        case 0: throw FindIssueError.notFound
        default: throw FindIssueError.ambiguous(results.issues)
        }

    }

    private func prepareRequest(_ request: URLRequest) async throws -> URLRequest {
        guard let credentials = self.credentials else {
            throw JiraError.custom("JIRA_CREDENTIALS not set")
        }
        var urlRequest = request

        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let base64LoginData = credentials.data(using: .utf8)!.base64EncodedString()
        urlRequest.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")

        return urlRequest
    }

    private func _search(
        _ search: JQL
    ) async throws -> SearchResults {
        terminal.write("Searching: ", debug: true)
        terminal.writeLine(search.rawValue, inColor: .cyan, debug: true)
        
        return try await self.request(
            path: "api/3/search",
            query: [
                "jql": search.rawValue,
                "maxResults": "500"
            ]
        )

    }
    
    private func request<T: Decodable>(
        as type: T.Type = T.self,
        path: String,
        query: [String: String]
    ) async throws -> T {
        guard
            var comps = URLComponents(
                url: base.appendingPathComponent(path),
                resolvingAgainstBaseURL: false
            )
        else {
            throw JiraError.custom("could build request")
        }

        comps.queryItems = query.map {
            URLQueryItem(name: $0.key, value: $0.value)
        }

        guard let urlRequest = comps.url.map({ URLRequest(url: $0) }) else {
            throw JiraError.custom("could build request")
        }
        
        

        do {
            let (data, _) = try await session.data(for: prepareRequest(urlRequest))
        
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            
            print("\(error)")
            throw JiraError.underlying(error)
        }

    }
}
