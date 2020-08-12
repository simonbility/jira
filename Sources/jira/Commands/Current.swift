//
//  File.swift
//
//
//  Created by Simon Anreiter on 28.05.20.
//

import ArgumentParser
import Foundation
import TSCBasic
import Combine
import TSCUtility

extension JiraError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .multipleIssuesFound(let issues):
            let names = issues.map(\.key).joined(separator: ", ")
            return """
            Multiple Issues found: (\(names))
            """
        case .notFound:
            return """
            Issue Not found
            """
        case .underlying(let e):
            return "\(e.localizedDescription)"
        case .custom(let m):
            return m
        }
    }
}

extension FindIssueError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .ambiguous(let issues):
            let names = issues.map(\.key).joined(separator: ", ")
            return """
            Multiple Issues found: (\(names))
            """
        case .notFound:
            return """
            Issue Not found
            """
        case .underlying(let e):
            return "\(e.localizedDescription)"
        }
    }
}


struct Current: ParsableCommand {

    enum Errors: String, LocalizedError {
        case noTicketPatternFound  = "could not extract ticket from branch"
        
        var errorDescription: String? { rawValue }
    }

    static var configuration = CommandConfiguration(
        abstract: "get current jira ticket from branch-name"
    )

    func run() throws {
        let key = try git.getIssueKeyFromBranch()
        let issue = try api.find(key: key)
        
        issue.write(to: terminal)
    }

}

