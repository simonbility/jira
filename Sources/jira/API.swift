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

    init(
        config: Configuration,
        credentials: String? = ProcessInfo.processInfo.environment["JIRA_CREDENTIALS"]
    ) {
        self.base = config.baseURL
        self.credentials = credentials
    }
 
    init(
        credentials: String? = ProcessInfo.processInfo.environment["JIRA_CREDENTIALS"],
        base: URL
    ) {
        self.credentials = credentials
        self.base = base
    }

    let session = URLSession.shared
    let base: URL
    let credentials: String?
    var cancellables: [AnyCancellable] = []
    
    
    func getCurrentUser() async throws -> User {
        return try await sendGet(path: "api/2/myself", query: [:])
    }

    func search(_ search: JQL) async throws -> SearchResults {
        return try await _search(search)
    }

    func activeSprint(boardID: String) async throws -> Sprint {
        return try await sendGet(
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
        
        return try await self.sendGet(
            path: "api/3/search",
            query: [
                "jql": search.rawValue,
                "maxResults": "500"
            ]
        )

    }
    
    func assignIssue(_ issue: Issue, userID: String) async throws {
        struct Payload: Encodable {
            let accountId: String
        }
        
        if terminal.isInteractive {
            terminal.writeLine("Assigning to you")
            issue.write(to: terminal)
        
        }
        
        try await self.sendPut(
            Payload(accountId: userID),
            path: "/api/3/issue/\(issue.key)/assignee")
    }
    
    func moveIssuesToSprint(
        sprint: Sprint,
        issues: [Issue]
    ) async throws {
        struct Payload: Encodable {
            let issues: [String]
        }
        
        if terminal.isInteractive {
            terminal.writeLine("Moving to Sprint: \(sprint.sanitizedName)")
            for issue in issues {
                issue.write(to: terminal)
            }
        }
        
        try await self.sendPost(Payload(issues: issues.map(\.key)), path: "agile/1.0/sprint/\(sprint.id)/issue")
    }
    
    private func sendGet<T: Decodable>(
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
    
    
    private func sendPayload<T: Encodable>(
        _ payload: T,
        method: String,
        path: String
    ) async throws {
        guard
            let comps = URLComponents(
                url: base.appendingPathComponent(path),
                resolvingAgainstBaseURL: false
            )
        else {
            throw JiraError.custom("could build request")
        }

        guard var urlRequest = comps.url.map({ URLRequest(url: $0) }) else {
            throw JiraError.custom("could build request")
        }
        
        let encoder = JSONEncoder()
        urlRequest.httpMethod = method
        urlRequest.httpBody = try encoder.encode(payload)
        
        do {
            let (_, response) = try await session.data(for: prepareRequest(urlRequest))
            
            let statusCode = (response as! HTTPURLResponse).statusCode
            
            switch statusCode {
            case 200...399: break
            default: throw JiraError.custom("Unexpected StatusCode \(statusCode)")
            }
        } catch {
            print("\(error)")
            throw JiraError.underlying(error)
        }

    }
    
    
    private func sendPost<T: Encodable>(
        _ payload: T,
        path: String
    ) async throws {
        try await sendPayload(payload, method: "POST", path: path)
    }
    
    private func sendPut<T: Encodable>(
        _ payload: T,
        path: String
    ) async throws {
       try await sendPayload(payload, method: "PUT", path: path)
    }
}
