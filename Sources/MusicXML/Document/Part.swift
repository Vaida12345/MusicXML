//
//  Part.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import AEXML
import DetailedDescription


extension MusicXMLDocument {

    public struct Part {

        public let id: String
        public let measures: [Measure]

        init(element: AEXMLElement) throws(ParseError) {
            assert(element.name == "part")

            self.id = try element.attribute(named: "id", as: String.self)

            var measures: [Measure] = []
            try element.forEachChild(named: "measure") { (child) throws(ParseError) in
                try measures.append(Measure(element: child))
            }
            self.measures = measures
        }

    }

}


extension MusicXMLDocument.Part: DetailedStringConvertible {

    public func detailedDescription(using descriptor: DetailedDescription.Descriptor<MusicXMLDocument.Part>) -> any DescriptionBlockProtocol {
        descriptor.value(self.id, for: \.measures)
    }

}
