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
    func search(_ search: JQL) throws -> SearchResults
    func find(key: String) throws -> Issue
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

    func search(_ search: JQL) throws -> SearchResults {
        return try _search(search)
    }

    func activeSprint(boardID: String) throws -> Sprint {
        guard
            var comps = URLComponents(
                url: base.appendingPathComponent("agile/1.0/board/\(boardID)/sprint"),
                resolvingAgainstBaseURL: false
            )
        else {
            throw JiraError.custom("could build request")
        }

        comps.queryItems = [
            URLQueryItem(name: "state", value: "active")
        ]

        guard let urlRequest = comps.url.map({ URLRequest(url: $0) }) else {
            throw JiraError.custom("could build request")
        }

        do {
            let results =
                try session
                .dataTaskPublisher(for: try prepareRequest(urlRequest))
                .map(\.data)
                .decode(type: SprintSearchResults.self, decoder: JSONDecoder())
                .mapError(JiraError.underlying)
                .awaitSingle()
            return results.values[0]
        } catch {
            print("\(error)")
            throw error
        }

    }

    func find(key: String) throws -> Issue {

        let jql = JQL(rawValue: "key = \(key)")

        let results = try self._search(jql)

        switch results.issues.count {
        case 1: return results.issues[0]
        case 0: throw FindIssueError.notFound
        default: throw FindIssueError.ambiguous(results.issues)
        }

    }

    private func prepareRequest(_ request: URLRequest) throws -> URLRequest {
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
    ) throws -> SearchResults {
        guard
            var comps = URLComponents(
                url: base.appendingPathComponent("api/3/search"),
                resolvingAgainstBaseURL: false
            )
        else {
            throw JiraError.custom("could build request")
        }

        terminal.write("Searching: ", debug: true)
        terminal.writeLine(search.rawValue, inColor: .cyan, debug: true)

        comps.queryItems = [
            URLQueryItem(name: "jql", value: search.rawValue),
            URLQueryItem(name: "maxResults", value: "500"),
        ]

        guard let urlRequest = comps.url.map({ URLRequest(url: $0) }) else {
            throw JiraError.custom("could build request")
        }

        return
            try session
            .dataTaskPublisher(for: try prepareRequest(urlRequest))
            .map(\.data)
            .decode(type: SearchResults.self, decoder: JSONDecoder())
            .mapError(JiraError.underlying)
            .awaitSingle()

    }
}

extension Publisher {

    func awaitSingle() throws -> Output {

        let group = DispatchGroup()
        var result: Result<Output, Failure>!
        group.enter()
        var cancellable: Cancellable? = self.sink(
            receiveCompletion: { comp in
                switch comp {
                case .failure(let e):
                    result = .failure(e)
                case .finished: break
                }
                group.leave()
            },
            receiveValue: {
                result = .success($0)
            }
        )

        group.wait()
        cancellable?.cancel()
        cancellable = nil

        return try result!.get()
    }
}
