//
//  ParseError.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import AEXML


indirect enum ParseError: Error {
    case typeMismatch(expected: String, actual: String)
    case noSuchChild(name: String)
    case noSuchAttribute(name: String)
    case childNodeError(name: String, error: ParseError)
    case attributeError(name: String, error: ParseError)
    case invalidChildCount(expected: Int, actual: Int)
    case invalidValue(actual: String, acceptableValues: [String])
}


extension AEXMLElement {

    func asText() throws(ParseError) -> String {
        guard let value = self.value else {
            throw .typeMismatch(expected: "String", actual: "nil")
        }
        return value
    }

    func asDoubleContainer() throws(ParseError) -> Double {
        let string = try self.asTextContainer()
        guard let value = Double(string) else { throw ParseError.typeMismatch(expected: "Double", actual: "String") }
        return value
    }

    func asIntContainer() throws(ParseError) -> Int {
        let string = try self.asTextContainer()
        guard let value = Int(string) else { throw ParseError.typeMismatch(expected: "Int", actual: "String (\(string))") }
        return value
    }

    func asEnumContainer<T>() throws(ParseError) -> T where T: RawRepresentable, T.RawValue == String, T: CaseIterable {
        let string = try self.asTextContainer()
        guard let value = T(rawValue: string) else { throw ParseError.invalidValue(actual: string, acceptableValues: T.allCases.map(\.rawValue)) }
        return value
    }

    func asEnum<T>() throws(ParseError) -> T where T: RawRepresentable, T.RawValue == String, T: CaseIterable {
        let string = try self.asText()
        guard let value = T(rawValue: string) else { throw ParseError.invalidValue(actual: string, acceptableValues: T.allCases.map(\.rawValue)) }
        return value
    }

    /// `<part-name>Piano</part-name>`
    func asTextContainer() throws(ParseError) -> String {
        guard let value = self.value else {
            throw .typeMismatch(expected: "String", actual: "nil")
        }
        return value
    }

    func child(named name: String) throws(ParseError) -> AEXMLElement {
        guard let child = self.children.first(where: { $0.name == name }) else {
            throw .noSuchChild(name: name)
        }
        return child
    }

    func hasChild(named name: String) -> Bool {
        self.children.contains(where: { $0.name == name })
    }

    /// Expected child as an element.
    func withChild<T>(named name: String, _ body: (AEXMLElement) throws(ParseError) -> T) throws(ParseError) -> T {
        let child = try self.child(named: name)

        do {
            return try body(child)
        } catch {
            throw .childNodeError(name: name, error: error)
        }
    }

    /// Expected child as an element.
    @_disfavoredOverload
    func withOptionalChild<T>(named name: String, _ body: (AEXMLElement) throws(ParseError) -> T) throws(ParseError) -> T? {
        guard let child = self.children.first(where: { $0.name == name }) else { return nil }

        do {
            return try body(child)
        } catch {
            throw .childNodeError(name: name, error: error)
        }
    }
    
    /// Expected child as an element.
    func withOptionalChild<T>(named name: String, _ body: (AEXMLElement) throws(ParseError) -> T?) throws(ParseError) -> T? {
        guard let child = self.children.first(where: { $0.name == name }) else { return nil }
        
        do {
            return try body(child)
        } catch {
            throw .childNodeError(name: name, error: error)
        }
    }

    /// Expected child as an element.
    func withChild<T>(named name: String, _ body: (AEXMLElement) -> () throws(ParseError) -> T) throws(ParseError) -> T {
        let child = try self.child(named: name)

        do {
            return try body(child)()
        } catch {
            throw .childNodeError(name: name, error: error)
        }
    }

    /// Expected child as an element.
    func withOptionalChild<T>(named name: String, _ body: (AEXMLElement) -> () throws(ParseError) -> T) throws(ParseError) -> T? {
        guard let child = self.children.first(where: { $0.name == name }) else { return nil }

        do {
            return try body(child)()
        } catch {
            throw .childNodeError(name: name, error: error)
        }
    }

    /// Expected child as an element.
    func forEachChild(named name: String, _ body: (AEXMLElement) throws(ParseError) -> Void) throws(ParseError) {
        let children = self.children
        var counter = 0
        for child in children where child.name == name {
            do {
                try body(child)
            } catch {
                throw .childNodeError(name: name + " #\(counter)", error: error)
            }
            counter += 1
        }
    }

}


extension AEXMLElement {

    @_disfavoredOverload
    func attribute<T>(named name: String, as type: T.Type = T.self) throws(ParseError) -> T where T: LosslessStringConvertible {
        guard let attribute = self.attributes[name] else {
            throw .noSuchAttribute(name: name)
        }
        guard let object = T(attribute) else {
            throw .attributeError(name: name, error: .typeMismatch(expected: "\(T.self)", actual: "\(String.self)"))
        }
        return object
    }

    func attribute(named name: String, as type: String.Type = String.self) throws(ParseError) -> String {
        guard let attribute = self.attributes[name] else {
            throw .noSuchAttribute(name: name)
        }
        return attribute
    }

    func attribute<T>(named name: String, as type: T.Type = T.self) throws(ParseError) -> T where T: RawRepresentable, T: CaseIterable, T.RawValue == String {
        guard let attribute = self.attributes[name] else {
            throw .noSuchAttribute(name: name)
        }
        guard let result = T(rawValue: attribute) else {
            throw .attributeError(name: name, error: .invalidValue(actual: attribute, acceptableValues: T.allCases.map(\.rawValue)))
        }
        return result
    }

}
