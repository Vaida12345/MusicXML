//
//  PartList.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import AEXML
import DetailedDescription


extension MusicXMLDocument {

    public struct PartList: RandomAccessCollection {
        
        private let scores: [Element]

        public var startIndex: Int { self.scores.startIndex }
        public var endIndex: Int { self.scores.endIndex }
        public subscript(position: Int) -> Element { self.scores[position] }

        init(element: AEXMLElement) throws(ParseError) {
            var scores: [Element] = []
            try element.forEachChild(named: "score-part") { (scorePart) throws(ParseError) in
                try scores.append(Element(element: scorePart))
            }
            self.scores = scores
        }
        
        public init(scores: [MusicXMLDocument.PartList.Element]) {
            self.scores = scores
        }

        public struct Element {
           
            public let id: String
            public let name: String
            public let instrument: String?

            init(element: AEXMLElement) throws(ParseError) {
                self.id = try element.attribute(named: "id", as: String.self)
                
                self.name = try element.withChild(named: "part-name", AEXMLElement.asTextContainer)
                self.instrument = try element.withOptionalChild(named: "score-instrument") { (child) throws(ParseError) in
                    try child.withChild(named: "instrument-name", AEXMLElement.asTextContainer)
                }
            }
            
            public init(id: String, name: String, instrument: String? = nil) {
                self.id = id
                self.name = name
                self.instrument = instrument
            }
        }
    }

}


extension MusicXMLDocument.PartList: DetailedStringConvertible {

    public func detailedDescription(using descriptor: DetailedDescription.Descriptor<MusicXMLDocument.PartList>) -> any DescriptionBlockProtocol {
        descriptor.sequence("", of: self.scores)
            .hideIndex()
    }

}


extension MusicXMLDocument.PartList.Element: CustomStringConvertible {

    public var description: String {
        self.id + " (" + self.name + ")"
    }

}
