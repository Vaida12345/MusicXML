//
//  MusicXMLDocument.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import DetailedDescription
import Essentials


public struct MusicXMLDocument {
    
    public let version: String?
    public let partList: PartList
    public let parts: [Part]
    
    init(data: Data) throws {
        let document: XMLDocument
        
        if Array(data[0..<2]) == [Character("P").asciiValue!, Character("K").asciiValue!] {
            document = try decodeMXL(data: data)
        } else {
            document = try XMLDocument(data: data)
        }
        let root = document.rootElement()!
        
        self.version = try? root.attribute(named: "version", as: String.self)
        self.partList = try root.withChild(named: "part-list", PartList.init)
        
        var parts: [Part] = []
        try root.forEachChild(named: "part") { (child) throws(ParseError) in
            try parts.append(Part(element: child))
        }
        self.parts = parts
    }
}


extension MusicXMLDocument: DetailedStringConvertible {
    
    public func detailedDescription(using descriptor: DetailedDescription.Descriptor<MusicXMLDocument>) -> any DescriptionBlockProtocol {
        var title = "MusicXML"
        if let version {
            title += " (v\(version))"
        }
        
        return descriptor.container(title) {
            descriptor.value(for: \.partList)
            descriptor.value(for: \.parts)
                .hideIndex()
        }
    }
    
}
