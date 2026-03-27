//
//  Measure Attributes.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import AEXML
import DetailedDescription


extension MusicXMLDocument.Measure {

    public struct Attributes {

        public let divisions: Int?
        public let keySignature: KeySignature?
        public let timeSignature: TimeSignature?
        public let staves: Int?
        public let clef: Clef?

        init(element: AEXMLElement) throws(ParseError) {
            assert(element.name == "attributes")

            self.divisions = try element.withOptionalChild(named: "divisions", AEXMLElement.asIntContainer)

            self.keySignature = try element.withOptionalChild(named: "key", KeySignature.init)
            self.timeSignature = try element.withOptionalChild(named: "time", TimeSignature.init)

            self.staves = try element.withOptionalChild(named: "staves", AEXMLElement.asIntContainer)

            self.clef = try element.withOptionalChild(named: "clef", Clef.init)
        }

    }

}


extension MusicXMLDocument.Measure.Attributes {

    public struct KeySignature: Equatable {
        public let octave: [Int]
        /// Indicates that the old key signature should be cancelled before the new one appears
        public let cancel: Bool
        
        public let value: Value
        
        public enum Value: Equatable {
            /// The number of flats or sharps in a traditional key signature
            ///
            /// Negative numbers are used for flats and positive numbers for sharps, reflecting the key's placement within the circle of fifths
            case traditional(fifths: Int, mode: Mode?)
            
            case nonTraditional([NonTraditionalValue])
            
            case none
            
            public struct NonTraditionalValue: Equatable {
                public let step: MusicXMLDocument.Note.Pitch.Step
                public let alter: Double
            }
        }

        static var none: KeySignature {
            KeySignature(octave: [], cancel: false, value: .none)
        }

        init(octave: [Int], cancel: Bool, value: Value) {
            self.octave = octave
            self.cancel = cancel
            self.value = .none
        }

        init(element: AEXMLElement) throws(ParseError) {
            assert(element.name == "key")

            var octave: [Int] = []
            try element.forEachChild(named: "key-octave") { (octaveElement) throws(ParseError) in
                try octave.append(octaveElement.asIntContainer())
            }
            self.octave = octave

            self.cancel = element.hasChild(named: "cancel")
            
            if let fifths = try element.withOptionalChild(named: "fifths", AEXMLElement.asIntContainer) {
                if fifths == 0 {
                    self.value = .none
                } else {
                    let mode: Mode? = try element.withOptionalChild(named: "mode", AEXMLElement.asEnumContainer)
                    self.value = .traditional(fifths: fifths, mode: mode)
                }
            } else {
                var step: MusicXMLDocument.Note.Pitch.Step?
                
                var values: [Value.NonTraditionalValue] = []
                for child in element.children {
                    guard let value = child.value else { continue }
                    if child.name == "key-step" {
                        guard let _step = MusicXMLDocument.Note.Pitch.Step(rawValue: value) else { throw .invalidValue(actual: value, acceptableValues: MusicXMLDocument.Note.Pitch.Step.allCases.map(\.rawValue)) }
                        step = _step
                    } else if child.name == "key-alter" {
                        guard let step else { continue }
                        guard let alter = Double(value) else { throw .typeMismatch(expected: "Double", actual: "String") }
                        values.append(Value.NonTraditionalValue(step: step, alter: alter))
                    }
                }
                
                if values.isEmpty {
                    self.value = .none
                } else {
                    self.value = .nonTraditional(values)
                }
            }
        }

        public enum Mode: String, CaseIterable, Equatable {
            case major, minor
        }
    }

    public struct TimeSignature: CustomStringConvertible {
        public let beats: Int
        public let beatType: Int

        public var description: String {
            "\(beats)/\(beatType)"
        }

        init(element: AEXMLElement) throws(ParseError) {
            assert(element.name == "time")

            self.beats = try element.withChild(named: "beats", AEXMLElement.asIntContainer)
            self.beatType = try element.withChild(named: "beat-type", AEXMLElement.asIntContainer)
        }
    }

    public struct Clef {
        public let sign: Sign
        /// Standard values are 2 for the G sign (treble clef), 4 for the F sign (bass clef), and 3 for the C sign (alto clef)
        public let line: Int

        init(element: AEXMLElement) throws(ParseError) {
            assert(element.name == "clef")

            self.sign = try element.withChild(named: "sign", AEXMLElement.asEnumContainer)
            self.line = try element.withChild(named: "line", AEXMLElement.asIntContainer)
        }

        public enum Sign: String, CaseIterable, CustomStringConvertible {
            case treble = "G", bass = "F"

            public var description: String {
                switch self {
                case .treble: ".treble"
                case .bass: ".bass"
                }
            }
        }
    }

}


extension MusicXMLDocument.Measure.Attributes: DetailedStringConvertible {

    public func detailedDescription(using descriptor: DetailedDescription.Descriptor<MusicXMLDocument.Measure.Attributes>) -> any DescriptionBlockProtocol {
        descriptor.container {
            descriptor.optional(for: \.divisions)
            if keySignature != .none {
                descriptor.value("keySignature", of: keySignature)
            }
            descriptor.optional(for: \.staves)
            descriptor.value(for: \.clef)
        }
    }

}
