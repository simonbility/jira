//
//  File.swift
//
//
//  Created by Simon Anreiter on 25.05.20.
//

import Foundation
import TSCBasic

extension DefaultStringInterpolation {
    mutating func appendInterpolation(commaSeparated ids: [String]) {
        self.appendLiteral("\(ids.joined(separator: ","))")
    }
}

func comparing<Base, Value: Comparable>(
    _ keyPath: KeyPath<Base, Value>
) -> (Base, Base) -> Bool {
    return { l, r in
        l[keyPath: keyPath] < r[keyPath: keyPath]
    }
}

struct JQL: Codable, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: String) {
        self.rawValue = value
    }

    func `in`(_ collection: JQL...) -> JQL {
        return JQL(
            rawValue: "\(rawValue) in (\(collection.map { $0.rawValue }.joined(separator: ", ")))"
        )
    }

    func and(_ other: JQL) -> JQL {
        return JQL(
            rawValue: "\(rawValue) AND \(other.rawValue)"
        )
    }

    func or(_ other: JQL) -> JQL {
        return JQL(
            rawValue: "\(rawValue) OR \(other.rawValue)"
        )
    }

    static func & (lhs: JQL, rhs: JQL) -> JQL {
        lhs.and(rhs)
    }

    static func | (lhs: JQL, rhs: JQL) -> JQL {
        lhs.or(rhs)
    }
}

struct SearchResults: Codable {
    let issues: [Issue]
}

struct Issue: Codable {

    struct Component: Codable, Hashable, Comparable, CustomStringConvertible {
        let `self`: URL
        let id: String
        let name: String
        
        var description: String { name }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Issue.Component, rhs: Issue.Component) -> Bool {
            lhs.id == rhs.id
        }
        
        static func < (lhs: Issue.Component, rhs: Issue.Component) -> Bool {
            lhs.id < rhs.id
        }
        
    }

    struct IssueType: Codable, Hashable, Comparable {
        let `self`: URL
        let id: String
        let name: String
        let description: String
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Issue.IssueType, rhs: Issue.IssueType) -> Bool {
            lhs.id == rhs.id
        }
        
        static func < (lhs: Issue.IssueType, rhs: Issue.IssueType) -> Bool {
            lhs.id < rhs.id
        }
        
    }

    struct Status: Codable, Comparable {
        let `self`: URL
        let id: String
        let name: String
        let description: String
        let statusCategory: Category

        public static func < (lhs: Status, rhs: Status) -> Bool {
            return (lhs.statusCategory, lhs.name) < (rhs.statusCategory, rhs.name)
        }

        struct Category: Codable, Comparable {
            let `self`: URL
            let id: Int
            let name: String
            let colorName: String

            private static let knownCategories = [
                "open",
                "done",
            ]

            private var ordinal: Int {
                return Category.knownCategories.firstIndex(of: name)
                    ?? Category.knownCategories.count
            }

            public static func < (lhs: Category, rhs: Category) -> Bool {
                return (lhs.ordinal, lhs.name) < (lhs.ordinal, rhs.name)
            }

        }

        var terminalColor: TerminalController.Color {
            switch self.statusCategory.colorName {
            case "green": return .green
            case "yellow": return .yellow
            case "blue-gray": return .cyan
            default:
                print("unhandled", self.statusCategory.colorName)
                return .red
            }
        }
    }

    //    let status: Status
    let `self`: URL
    let key: String
    let fields: Fields
    
    var componentKey: String {
        fields.components.sorted().map(\.name).joined(separator: ", ")
    }

    var sanitizedSummary: String {
        let droppedPrefixes = fields.components.map { "\($0.name): " }
        var text = self.fields.summary

        for prefix in droppedPrefixes where text.hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count))
        }

        return text
    }

    var canonicalName: String {
        return
            sanitizedSummary
            .split { !$0.isLetter && !$0.isNumber }
            .map { $0.lowercased() }
            .joined(separator: "-")

    }

    var branch: (type: String, name: String) {
        (branchType, String("\(key)-\(canonicalName)".prefix(60)))
    }

    var branchType: String {
        let bugTypes = ["defect", "bug"]
        return bugTypes.contains(self.fields.issuetype.name.lowercased())
            ? "bugfix" : "feature"
    }

    struct Fields: Codable {
        let summary: String
        let components: [Component]
        let issuetype: IssueType
        let status: Status
    }

    func write(to console: Console) {
        console.write("- ")
        console.write(key, inColor: fields.status.terminalColor)
        console.write(": \(sanitizedSummary)")
        //        tc.write(fields.status.name, inColor: fields.status.terminalColor)
        //        tc.write("]")
        console.endLine()
    }

    var attributes: [(key: String, value: String, color: TerminalController.Color)] {

        [
            ("link     ", "https://imobility.atlassian.net/browse/\(key)", .cyan)
            //            ("status   ", fields.status.name, fields.status.terminalColor),
            //            ("branch   ", "\(branch.type)/\(branch.name)", .noColor),
            //            ("changelog", "\(fields.summary) [\(key)](https://imobility.atlassian.net/browse/\(key))",.noColor)
        ]
    }

}
