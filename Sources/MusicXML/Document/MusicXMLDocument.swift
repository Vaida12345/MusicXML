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
    public let title: String?
    public let composer: String?
    public let credits: [Credit]
    /// Names of software that created the encoding, in document order.
    public let encodingSoftware: [String]

    public init(data: Data) throws {
        let document: AEXMLDocument

        if data.starts(with: [0x50, 0x4B]) { // PK (ZIP magic number)
            document = try decodeMXL(data: data)
        } else {
            document = try AEXMLDocument(xml: data)
        }
        let root = document.root

        self.version = root.attributes["version"]
        self.title = try root.withOptionalChild(named: "work") { (work) throws(ParseError) in
            try work.withOptionalChild(named: "work-title", AEXMLElement.asTextContainer)
        }
        self.composer = root.children.first(where: { $0.name == "identification" })?
            .children.first(where: { $0.name == "creator" && $0.attributes["type"] == "composer" })?.value
        self.encodingSoftware = try root.withOptionalChild(named: "identification") { (identification) throws(ParseError) in
            try identification.withOptionalChild(named: "encoding") { (encoding) throws(ParseError) in
                try encoding.mapChildren(named: "software") { (software) throws(ParseError) in
                    try software.asTextContainer()
                }
            } ?? []
        } ?? []
        self.credits = try root.mapChildren(named: "credit", Credit.init)
        self.partList = try root.withChild(named: "part-list", PartList.init)

        var parts: [Part] = []
        try root.forEachChild(named: "part") { (child) throws(ParseError) in
            try parts.append(Part(element: child))
        }
        self.parts = parts
        self.layout = try Layout(root: root)
    }
    
    public init(layout: MusicXMLDocument.Layout = .init(), version: String? = nil, partList: MusicXMLDocument.PartList, parts: [MusicXMLDocument.Part], title: String? = nil, composer: String? = nil, credits: [Credit] = [], encodingSoftware: [String] = []) {
        self.layout = layout
        self.version = version
        self.partList = partList
        self.parts = parts
        self.title = title
        self.composer = composer
        self.credits = credits
        self.encodingSoftware = encodingSoftware
    }
}


extension MusicXMLDocument: DetailedStringConvertible {

    public func detailedDescription(using descriptor: DetailedDescription.Descriptor<MusicXMLDocument>) -> any DescriptionBlockProtocol {
        var title = "MusicXML"
        if let version {
            title += " (v\(version))"
        }

        return descriptor.container(title) {
            descriptor.optional(for: \.title)
            descriptor.optional(for: \.composer)
            descriptor.value(for: \.encodingSoftware)
            descriptor.value(for: \.credits)
            descriptor.value(for: \.partList)
            descriptor.value(for: \.layout)
            descriptor.value(for: \.parts)
                .hideIndex()
        }
    }

}
