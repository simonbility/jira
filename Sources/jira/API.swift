//
//  File.swift
//
//
//  Created by Simon Anreiter on 23.05.20.
//

import Combine
import Foundation
import TSCBasic

enum JiraError: Error {
    case underlying(Error)
    case multipleIssuesFound([Issue])
    case notFound
}

protocol JiraAPI {

    func search(
        _ search: JQL,
        completion: @escaping (Result<SearchResults, JiraError>) -> Void
    )

    func find(
        key: String,
        completion: @escaping (Result<Issue, FindIssueError>) -> Void
    )
}

enum FindIssueError: Error {
    case ambiguous([Issue])
    case notFound
    case underlying(Error)
}

class API: JiraAPI {

    init(credentials: String) {
        self.credentials = credentials
    }

    let session = URLSession.shared
    let base = URL(string: "https://imobility.atlassian.net/rest/api")!
    let credentials: String
    var cancellables: [AnyCancellable] = []

    func search(
        _ search: JQL,
        completion: @escaping (Result<SearchResults, JiraError>) -> Void
    ) {
        let tc = TerminalController(stream: stdoutStream)
        tc?.write("Searching Issues: ")
        tc?.write(search.rawValue, inColor: .cyan)

        _search(search) { result in
            switch result {
            case .success(let res):
                tc?.writeCompact(color: .green, "\(res.issues.count) results")
            case .failure(let e):
                tc?.writeCompact(color: .red, "\(e)")
            }
            tc?.endLine()
            completion(result)
        }
    }

    func find(
        key: String,
        completion: @escaping (Result<Issue, FindIssueError>) -> Void
    ) {
        let jql = JQL(rawValue: "key = \(key)")
        let tc = TerminalController(stream: stdoutStream)
        tc?.write("Fetching Issue: ")
        tc?.write(jql.rawValue, inColor: .cyan)

        self._search(jql) { res in

            let finalResult: Result<Issue, FindIssueError> =
                res
                .mapError(FindIssueError.underlying)
                .flatMap { val in
                    switch val.issues.count {
                    case 0: return .failure(.notFound)
                    case 1: return .success(val.issues[0])
                    default: return .failure(.ambiguous(val.issues))
                    }
                }

            switch finalResult {
            case .success(let res):
                tc?.writeCompact(color: .green, res.fields.summary)
            case .failure(let e):
                tc?.writeCompact(color: .red, "\(e)")
            }

            completion(finalResult)

        }
    }

    private func _search(
        _ search: JQL,
        completion: @escaping (Result<SearchResults, JiraError>) -> Void
    ) {
        guard
            var comps = URLComponents(
                url: base.appendingPathComponent("/3/search"),
                resolvingAgainstBaseURL: false
            )
        else {
            return
        }

        comps.queryItems = []
        comps.queryItems?.append(URLQueryItem(name: "jql", value: search.rawValue))

        guard var urlRequest = comps.url.map({ URLRequest(url: $0) }) else {
            return
        }

        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let base64LoginData = credentials.data(using: .utf8)!.base64EncodedString()
        urlRequest.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")

        session.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .decode(type: SearchResults.self, decoder: JSONDecoder())
            .sink(
                receiveCompletion: { comp in
                    switch comp {
                    case .failure(let e):
                        completion(.failure(JiraError.underlying(e)))
                    case .finished: break
                    }
                },
                receiveValue: {
                    completion(.success($0))
                }
            )
            .store(in: &cancellables)

    }
}
