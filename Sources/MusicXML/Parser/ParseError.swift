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
    
    /// Expected child as an element.
    func withChild<T>(named name: String, _ body: (XMLElement) throws(ParseError) -> T) throws(ParseError) -> T {
        let child = try self.child(named: name)
        
        do {
            let child = try child.asElement()
            
            return try body(child)
        } catch {
            throw ParseError.childNodeError(name: "score-part", error: error)
        }
    }
    
}


extension XMLElement {
    
    func attribute<T>(named name: String, as type: T.Type) throws(ParseError) -> T {
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
    
}
