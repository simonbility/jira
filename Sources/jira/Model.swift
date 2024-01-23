import Foundation
import TSCBasic

extension DefaultStringInterpolation {
    mutating func appendInterpolation(commaSeparated ids: [String]) {
        appendLiteral("\(ids.joined(separator: ","))")
    }
}

func comparing<Base, Value: Comparable>(
    _ keyPath: KeyPath<Base, Value>
) -> (Base, Base) -> Bool {
    { l, r in
        l[keyPath: keyPath] < r[keyPath: keyPath]
    }
}

struct User: Codable {
    let displayName: String
    let accountId: String
}

struct SearchResults: Codable {
    let issues: [Issue]
}

struct Sprint: Codable {
    let id: Int
    let name: String
    let goal: String?

    var sanitizedName: String {
        let regex = try! NSRegularExpression(
            pattern: #"\(.*\)"#,
            options: NSRegularExpression.Options.caseInsensitive
        )
        let range = NSMakeRange(0, name.count)
        return regex.stringByReplacingMatches(
            in: name,
            options: [],
            range: range,
            withTemplate: ""
        ).trimmingCharacters(in: .whitespaces)
    }
}

struct SprintSearchResults: Codable {
    let values: [Sprint]
}

class Issue: Codable {
    var loggedTime: Int {
        fields.progress?.progress ?? 0
    }

    var isBugOrDefect: Bool {
        let t = fields.issuetype.name.lowercased()

        return t == "bug" || t == "defect"
    }

    var isEpic: Bool {
        let t = fields.issuetype.name.lowercased()

        return t == "epic"
    }

    static func findIssueKey(_ string: String, wholeMatch: Bool) -> String? {
        let regex = wholeMatch ? #"^[A-Z]+-[0-9]+$"# : #"[A-Z]+-[0-9]+"#
        let nsString = string as NSString
        let range = nsString.range(of: regex, options: .regularExpression)

        guard range.location != NSNotFound else {
            return nil
        }

        return nsString.substring(with: range)
    }

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

        private var index: Int {
            switch name.lowercased() {
            case "story": return 0
            case "improvement": return 1
            case "operations": return 2
            case "bug": return 3
            case "defect": return 4
            default: return 5
            }
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: Issue.IssueType, rhs: Issue.IssueType) -> Bool {
            lhs.id == rhs.id
        }

        static func < (lhs: Issue.IssueType, rhs: Issue.IssueType) -> Bool {
            (lhs.index, lhs.id) < (rhs.index, rhs.id)
        }
    }

    struct Status: Codable, Comparable {
        let `self`: URL
        let id: ID
        let name: String
        let description: String
        let statusCategory: Category

        struct ID: Codable, Equatable {
            let rawValue: String

            static let inProgress = ID(rawValue: "10484")

            init(rawValue: String) {
                self.rawValue = rawValue
            }

            init(from decoder: Decoder) throws {
                var container = try decoder.singleValueContainer()
                self.rawValue = try container.decode(String.self)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(self.rawValue)
            }
        }

        public static func < (lhs: Status, rhs: Status) -> Bool {
            (lhs.statusCategory, lhs.name) < (rhs.statusCategory, rhs.name)
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
                Category.knownCategories.firstIndex(of: name)
                    ?? Category.knownCategories.count
            }

            public static func < (lhs: Category, rhs: Category) -> Bool {
                (lhs.ordinal, lhs.name) < (lhs.ordinal, rhs.name)
            }
        }

        var terminalColor: TerminalController.Color {
            switch statusCategory.colorName {
            case "green": return .green
            case "yellow": return .yellow
            case "blue-gray": return .cyan
            default:
                print("unhandled", statusCategory.colorName)
                return .red
            }
        }
    }

    //    let status: Status
    let `self`: URL
    let id: String
    let key: String
    let fields: Fields
    var isClosed: Bool {
        fields.status.name.lowercased() == "closed"
    }

    var componentKey: String {
        fields.components?.sorted().map(\.name).joined(separator: ", ") ?? ""
    }

    var keyAndSummary: String {
        "\(key): \(fields.summary)"
    }

    var sanitizedSummary: String {
        let droppedPrefixes = fields.components?.map { "\($0.name): " } ?? []
        var text = fields.summary

        for prefix in droppedPrefixes where text.hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count))
        }

        return text
    }

    var canonicalName: String {
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
        return bugTypes.contains(fields.issuetype.name.lowercased())
            ? "bugfix" : "feature"
    }

    var fixVersions: [FixVersion] {
        fields.fixVersions ?? []
    }

    class Fields: Codable {
        let summary: String
        let components: [Component]?
        let progress: Progress?
        let issuetype: IssueType
        let status: Status
        let fixVersions: [FixVersion]?
        let parent: Issue?

        struct Progress: Codable {
            let progress: Int
        }
    }

    struct FixVersion: Codable {
        let name: String
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
            ("link     ", "https://imobility.atlassian.net/browse/\(key)", .cyan),
            //            ("status   ", fields.status.name, fields.status.terminalColor),
            //            ("branch   ", "\(branch.type)/\(branch.name)", .noColor),
            //            ("changelog", "\(fields.summary)
            //            [\(key)](https://imobility.atlassian.net/browse/\(key))",.noColor)
        ]
    }
}
