//
//  File.swift
//
//
//  Created by Simon Anreiter on 23.05.20.
//

import Combine
import Foundation
import TSCBasic
import ArgumentParser

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
    let base = URL(string: "https://imobility.atlassian.net/rest/api")!
    let credentials: String?
    var cancellables: [AnyCancellable] = []

    func search(_ search: JQL) throws -> SearchResults {
//        let tc = TerminalController(stream: stdoutStream)
//        tc?.write("Searching Issues: ")
//        tc?.write(search.rawValue, inColor: .cyan)
//        tc?.endLine()

        return try _search(search)
    }

    func find(key: String) throws -> Issue {
        
        let jql = JQL(rawValue: "key = \(key)")
        let tc = TerminalController(stream: stdoutStream)
        tc?.write("Fetching Issue: ")
        tc?.write(jql.rawValue, inColor: .cyan)
        tc?.endLine()

        let results = try self._search(jql)
        
        switch results.issues.count {
        case 1: return results.issues[0]
        case 0: throw FindIssueError.notFound
        default: throw FindIssueError.ambiguous(results.issues)
        }
            
    }

    private func _search(
        _ search: JQL
    ) throws -> SearchResults {
        guard
            var comps = URLComponents(
                url: base.appendingPathComponent("/3/search"),
                resolvingAgainstBaseURL: false
            )
        else {
            throw JiraError.custom("could build request")
        }

        comps.queryItems = []
        comps.queryItems?.append(URLQueryItem(name: "jql", value: search.rawValue))

        guard var urlRequest = comps.url.map({ URLRequest(url: $0) }) else {
            throw JiraError.custom("could build request")
        }
        guard let credentials = self.credentials else {
            throw JiraError.custom("JIRA_CREDENTIALS not set")
        }

        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let base64LoginData = credentials.data(using: .utf8)!.base64EncodedString()
        urlRequest.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")

        return try session
            .dataTaskPublisher(for: urlRequest)
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
