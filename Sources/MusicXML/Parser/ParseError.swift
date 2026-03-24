//
//  ParseError.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation


indirect enum ParseError: Error {
    case kindMismatch(expected: XMLNode.Kind, actual: XMLNode.Kind)
    case typeMismatch(expected: String, actual: String)
    case noSuchChild(name: String)
    case noSuchAttribute(name: String)
    case childNodeError(name: String, error: ParseError)
    case attributeError(name: String, error: ParseError)
    case invalidChildCount(expected: Int, actual: Int)
    case invalidValue(actual: String, acceptableValues: [String])
}


extension XMLNode {
    
    func asElement() throws(ParseError) -> XMLElement {
        guard self.kind == .element, let element = self as? XMLElement else {
            throw .kindMismatch(expected: .element, actual: self.kind)
        }
        return element
    }
    
    func asText() throws(ParseError) -> String {
        guard self.kind == .text else {
            throw .kindMismatch(expected: .text, actual: self.kind)
        }
        guard let object = self.objectValue as? String else {
            let actualType = Swift.type(of: self.objectValue)
            throw .typeMismatch(expected: "\(String.self)", actual: "\(actualType)")
        }
        return object
    }
    
    func asDoubleContainer() throws(ParseError) -> Double {
        let string = try self.asTextContainer()
        guard let value = Double(string) else { throw ParseError.typeMismatch(expected: "Double", actual: "String") }
        return value
    }
    
    func asIntContainer() throws(ParseError) -> Int {
        let string = try self.asTextContainer()
        guard let value = Int(string) else { throw ParseError.typeMismatch(expected: "Int", actual: "String") }
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
        let element = try self.asElement()
        guard element.childCount == 1, let child = element.child(at: 0) else {
            throw .invalidChildCount(expected: 1, actual: element.childCount)
        }
        
        do {
            return try child.asText()
        } catch {
            throw .childNodeError(name: "[0]", error: error)
        }
    }
    
    func child(named name: String) throws(ParseError) -> XMLNode {
        guard let child = self.children?.first(where: { $0.name == name }) else {
            throw .noSuchChild(name: name)
        }
        return child
    }
    
    func hasChild(named name: String) -> Bool {
        (self.children ?? []).contains(where: { $0.name == name })
    }
    
    /// Expected child as an element.
    func withChild<T>(named name: String, _ body: (XMLElement) throws(ParseError) -> T) throws(ParseError) -> T {
        let child = try self.child(named: name)
        
        do {
            let child = try child.asElement()
            return try body(child)
        } catch {
            throw .childNodeError(name: name, error: error)
        }
    }
    
    /// Expected child as an element.
    func forEachChild(named name: String, _ body: (XMLElement) throws(ParseError) -> Void) throws(ParseError) {
        let children = self.children ?? []
        var counter = 0
        for child in children where child.name == name {
            do {
                let child = try child.asElement()
                try body(child)
            } catch {
                throw .childNodeError(name: name + " #\(counter)", error: error)
            }
            counter += 1
        }
    }
    
}


extension XMLElement {
    
    @_disfavoredOverload
    func attribute<T>(named name: String, as type: T.Type = T.self) throws(ParseError) -> T {
        guard let attribute = self.attribute(forName: name) else {
            throw .noSuchAttribute(name: name)
        }
        guard attribute.kind == .attribute else {
            throw .attributeError(name: name, error: .kindMismatch(expected: .attribute, actual: attribute.kind))
        }
        guard let object = attribute.objectValue as? T else {
            let actualType = Swift.type(of: attribute.objectValue)
            throw .attributeError(name: name, error: .typeMismatch(expected: "\(T.self)", actual: "\(actualType)"))
        }
        return object
    }
    
    func attribute<T>(named name: String, as type: T.Type = T.self) throws(ParseError) -> T where T: RawRepresentable, T: CaseIterable, T.RawValue == String {
        guard let attribute = self.attribute(forName: name) else {
            throw .noSuchAttribute(name: name)
        }
        guard attribute.kind == .attribute else {
            throw .attributeError(name: name, error: .kindMismatch(expected: .attribute, actual: attribute.kind))
        }
        guard let object = attribute.objectValue as? String else {
            let actualType = Swift.type(of: attribute.objectValue)
            throw .attributeError(name: name, error: .typeMismatch(expected: "\(String.self)", actual: "\(actualType)"))
        }
        guard let result = T(rawValue: object) else {
            throw .attributeError(name: name, error: .invalidValue(actual: object, acceptableValues: T.allCases.map(\.rawValue)))
        }
        return result
    }
    
}
