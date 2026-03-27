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
        
        public init(ending: MusicXMLDocument.Measure.BarLine.Ending? = nil, `repeat`: MusicXMLDocument.Measure.BarLine.Repeat? = nil) {
            self.ending = ending
            self.`repeat` = `repeat`
        }


        public struct Ending {
            
            /// Indicates which times the ending is played, similar to the time-only attribute used by other elements.
            public let number: [Int]
            public let type: StartStopDiscontinue

            init(element: AEXMLElement) throws(ParseError) {
                assert(element.name == "ending")

                self.number = try element.attribute(named: "number").split(separator: ",").map({ Int($0.trimmingCharacters(in: .whitespacesAndNewlines))! })
                self.type = try element.attribute(named: "type")
            }
            
            public init(number: [Int], type: MusicXMLDocument.Measure.StartStopDiscontinue) {
                self.number = number
                self.type = type
            }

        }

        public struct Repeat {
            
            public let direction: HorizontalDirection

            init(element: AEXMLElement) throws(ParseError) {
                assert(element.name == "repeat")

                self.direction = try element.attribute(named: "direction")
            }

            public init(direction: MusicXMLDocument.Measure.HorizontalDirection) {
                self.direction = direction
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
