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

        public struct Element {
            public var id: String
            public var name: String


            init(element: AEXMLElement) throws(ParseError) {
                self.id = try element.attribute(named: "id", as: String.self)

                var name: String = ""
                try element.withChild(named: "part-name") { (child) throws(ParseError) in
                    name = try child.asTextContainer()
                }

                self.name = name
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
