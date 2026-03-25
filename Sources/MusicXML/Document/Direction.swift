//
//  Direction.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-25.
//

import Foundation
import AEXML
import DetailedDescription
import MacroCollection


extension MusicXMLDocument.Measure {

    @accessingAssociatedValues
    public enum Direction {
        case metronome(Metronome)

        init?(element: AEXMLElement) throws(ParseError) {
            assert(element.name == "direction")
            let value: Direction? = try element.withChild(named: "direction-type") { type throws(ParseError) in
                guard let metronome = try type.withOptionalChild(named: "metronome", Metronome.init) else { return nil }
                return .metronome(metronome)
            }
            guard let value else { return nil }
            self = value
        }


        public struct Metronome {

            public let beatUnit: MusicXMLDocument.Note.NoteType
            public let dots: Int
            public let rhs: RHS?

            public enum RHS {
                case perMinute(Int)
                case beat(beatUnit: MusicXMLDocument.Note.NoteType, dots: Int)
            }

            init(element: AEXMLElement) throws(ParseError) {
                var iterator = element.children.makeIterator()
                guard let beatUnitElement = iterator.next() else { throw .invalidChildCount(expected: 1, actual: 0) }
                do {
                    guard beatUnitElement.name == "beat-unit" else { throw ParseError.noSuchChild(name: "beat-unit") }
                    self.beatUnit = try beatUnitElement.asEnumContainer()
                } catch {
                    throw .childNodeError(name: "beat-unit", error: error as! ParseError)
                }

                var dots = 0
                var next = iterator.next()
                while next?.name == "beat-unit-dot" {
                    dots += 1
                    next = iterator.next()
                }
                self.dots = dots

                while next?.name == "beat-unit-tied" { // skip this
                    next = iterator.next()
                }

                guard let next else { throw .invalidChildCount(expected: 2, actual: 1) }
                if next.name == "per-minute" {
                    self.rhs = (try? next.asIntContainer()).map({ .perMinute($0) })
                } else if next.name == "beat-unit", let rhsBeatUnit: MusicXMLDocument.Note.NoteType = try? next.asEnumContainer() {

                    var dots = 0
                    var next = iterator.next()
                    while next?.name == "beat-unit-dot" {
                        dots += 1
                        next = iterator.next()
                    }

                    self.rhs = .beat(beatUnit: rhsBeatUnit, dots: dots)
                } else {
                    self.rhs = nil
                }
            }
        }
    }
}


extension MusicXMLDocument.Measure.Direction: DetailedStringConvertible {

    public func detailedDescription(using descriptor: DetailedDescription.Descriptor<MusicXMLDocument.Measure.Direction>) -> any DescriptionBlockProtocol {
        descriptor.container {
            switch self {
            case .metronome(let metronome):
                descriptor.container("metronome") {
                    descriptor.value("beatUnit", of: metronome.beatUnit)
                    if metronome.dots != 0 {
                        descriptor.value("dots", of: metronome.dots)
                    }
                    if let rhs = metronome.rhs {
                        switch rhs {
                        case .perMinute(let int):
                            descriptor.value("per minute", of: int)
                        case .beat(let beatUnit, let dots):
                            descriptor.value("beatUnit", of: beatUnit)
                            if metronome.dots != 0 {
                                descriptor.value("dots", of: dots)
                            }
                        }
                    }
                }
            }
        }
    }
}
