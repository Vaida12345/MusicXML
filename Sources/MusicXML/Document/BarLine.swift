//
//  BarLine.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//


import Foundation
import AEXML
import DetailedDescription


extension MusicXMLDocument.Measure {

    public struct BarLine {

        public let ending: Ending?
        public let `repeat`: Repeat?

        init(element: AEXMLElement) throws(ParseError) {
            assert(element.name == "barline")

            self.ending = try element.withOptionalChild(named: "ending", Ending.init)
            self.repeat = try element.withOptionalChild(named: "repeat", Repeat.init)
        }


        public struct Ending {
            let content: String?
            let number: String
            let type: StartStopDiscontinue

            init(element: AEXMLElement) throws(ParseError) {
                assert(element.name == "ending")

                self.content = try? element.asTextContainer()
                self.number = try element.attribute(named: "number")
                self.type = try element.attribute(named: "type")
            }

        }

        public struct Repeat {
            public let direction: HorizontalDirection

            init(element: AEXMLElement) throws(ParseError) {
                assert(element.name == "repeat")

                self.direction = try element.attribute(named: "direction")
            }

        }

    }

}


extension MusicXMLDocument.Measure.BarLine: DetailedStringConvertible {

    public func detailedDescription(using descriptor: DetailedDescription.Descriptor<MusicXMLDocument.Measure.BarLine>) -> any DescriptionBlockProtocol {
        descriptor.container {
            descriptor.optional(for: \.ending)
            descriptor.optional(for: \.repeat)
        }
    }

}
