//
//  File.swift
//
//
//  Created by Simon Anreiter on 01.07.22.
//

import Foundation

struct IssueUpdates: Codable {
    var update: [String: [[String: JSON]]]

    mutating func remove(_ key: String, value: JSON) {
        self.update[key, default: []].append(["remove": value])
    }

    mutating func add(_ key: String, value: JSON) {
        self.update[key, default: []].append(["add": value])
    }
    
    
    mutating func set(_ key: String, value: JSON) {
        self.update[key, default: []].append(["set": value])
    }

    mutating func edit(_ key: String, value: JSON) {
        self.update[key, default: []].append(["edit": value])
    }
}

public enum JSON: Equatable, Hashable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSON])
    case dictionary([String: JSON])

    public var int: Int? {
        guard case .int(let value) = self else { return nil }
        return value
    }

    public var double: Double? {
        switch self {
        case .int(let value): return Double(value)
        case .double(let value): return value
        default: return nil
        }
    }

    public var string: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }

    public var dict: [String: JSON]? {
        guard case .dictionary(let value) = self else { return nil }
        return value
    }

    public var array: [JSON]? {
        guard case .array(let value) = self else { return nil }
        return value
    }

}

extension JSON: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension JSON: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: ArrayLiteralElement...) {
        self = .array(elements)
    }
    public typealias ArrayLiteralElement = JSON

}

extension JSON: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = JSON

    public init(dictionaryLiteral elements: (String, JSON)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension SingleValueDecodingContainer {

    fileprivate func decodeAsJSON<T: Decodable>(
        ofType: T.Type? = nil,
        _ transform: (T) -> JSON
    ) -> JSON? {
        (try? self.decode(T.self)).map(transform)
    }
}

extension JSON: Decodable {

    public init(from decoder: Decoder) throws {
        var object: JSON? = nil

        if let container = try? decoder.singleValueContainer(), !container.decodeNil() {
            object =
                container.decodeAsJSON(JSON.bool)
                ?? container.decodeAsJSON(JSON.int)
                ?? container.decodeAsJSON(JSON.double)
                ?? container.decodeAsJSON(JSON.string)
                ?? container.decodeAsJSON(JSON.array)
                ?? container.decodeAsJSON(JSON.dictionary)
        }
        self = object ?? .null
    }
}

extension JSON: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null: try container.encodeNil()
        case .array(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .dictionary(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        }
    }
}

public struct JSONCodingKey: CodingKey {
    let key: String

    public init?(intValue: Int) {
        return nil
    }

    public init?(stringValue: String) {
        key = stringValue
    }

    public var intValue: Int? {
        return nil
    }

    public var stringValue: String {
        return key
    }

}
