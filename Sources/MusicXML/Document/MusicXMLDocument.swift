//
//  MusicXMLDocument.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import AEXML
import DetailedDescription
import Essentials


public struct MusicXMLDocument {
    
    public let layout: Layout
    public let version: String?
    public let partList: PartList
    public let parts: [Part]

    public init(data: Data) throws {
        let document: AEXMLDocument

        if Array(data[0..<2]) == [Character("P").asciiValue!, Character("K").asciiValue!] {
            document = try decodeMXL(data: data)
        } else {
            document = try AEXMLDocument(xml: data)
        }
        let root = document.root

        self.version = root.attributes["version"]
        self.partList = try root.withChild(named: "part-list", PartList.init)

        var parts: [Part] = []
        try root.forEachChild(named: "part") { (child) throws(ParseError) in
            try parts.append(Part(element: child))
        }
        self.parts = parts
        self.layout = try Layout(root: root)
    }
    
    public init(layout: MusicXMLDocument.Layout, version: String? = nil, partList: MusicXMLDocument.PartList, parts: [MusicXMLDocument.Part]) {
        self.layout = layout
        self.version = version
        self.partList = partList
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
            descriptor.value(for: \.layout)
            descriptor.value(for: \.parts)
                .hideIndex()
        }
    }

}
