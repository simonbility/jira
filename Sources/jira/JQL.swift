import Foundation

public protocol ResultBuilder {
    associatedtype Element
    associatedtype FinalResult = [Element]

    static func buildExpression(_ expression: Element) -> [Element]
    static func buildIf(_ content: [Element]?) -> [Element]
    static func buildOptional(_ content: [Element]?) -> [Element]
    static func buildArray(_ content: [[Element]]) -> [Element]
    static func buildEither(first: [Element]) -> [Element]
    static func buildEither(second: [Element]) -> [Element]
    static func buildBlock(_ elements: [Element]...) -> [Element]
    static func buildFinalResult(_ elements: [Element]) -> FinalResult
}

extension ResultBuilder {
    public static func buildBlock(
        _ elements: [Element]...
    ) -> [Element] {
        elements.flatMap { $0 }
    }

    public static func buildExpression(
        _ expression: Element
    ) -> [Element] {
        [expression]
    }

    public static func buildIf(
        _ content: [Element]?
    ) -> [Element] { content ?? [] }

    public static func buildOptional(
        _ content: [Element]?
    ) -> [Element] { content ?? [] }

    public static func buildArray(
        _ content: [[Element]]
    ) -> [Element] { content.flatMap { $0 } }

    public static func buildEither(first: [Element]) -> [Element] {
        first
    }

    public static func buildEither(second: [Element]) -> [Element] {
        second
    }

    public static func buildFinalResult(_ elements: [Element]) -> FinalResult
        where FinalResult == [Element]
    {
        elements
    }
}

@resultBuilder
enum JQLBuilder: ResultBuilder {
    typealias Element = JQL
    typealias FinalResult = JQL

    static func buildFinalResult(_ elements: [JQL]) -> JQL {
        JQL(rawValue: elements.map(\.rawValue).joined(separator: " AND "))
    }

    public static func buildExpression(
        _ expression: String
    ) -> [Element] {
        [JQL(rawValue: expression)]
    }
}

struct JQL: Codable, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    let rawValue: String

    init(@JQLBuilder builder: () -> JQL) {
        self = builder()
    }

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: String) {
        rawValue = value
    }

    func `in`(_ collection: JQL...) -> JQL {
        JQL(
            rawValue: "\(rawValue) in (\(collection.map { $0.rawValue }.joined(separator: ", ")))"
        )
    }

    func and(_ other: JQL) -> JQL {
        JQL(
            rawValue: "\(rawValue) AND \(other.rawValue)"
        )
    }

    func or(_ other: JQL) -> JQL {
        JQL(
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
