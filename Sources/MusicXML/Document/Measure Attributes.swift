//
//  Measure Attributes.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import DetailedDescription


extension MusicXMLDocument.Measure {
    
    public struct Attributes {
        
        public let divisions: Int?
        public let keySignature: KeySignature
        public let timeSignature: TimeSignature
        public let staves: Int?
        public let clef: Clef
        
        init(element: XMLElement) throws(ParseError) {
            assert(element.name == "attributes")
            
            self.divisions = try element.withOptionalChild(named: "divisions", XMLElement.asIntContainer)
            
            self.keySignature = try element.withChild(named: "key", KeySignature.init)
            self.timeSignature = try element.withChild(named: "time", TimeSignature.init)
            
            self.staves = try element.withOptionalChild(named: "staves", XMLElement.asIntContainer)
            
            self.clef = try element.withChild(named: "clef", Clef.init)
        }
        
    }
    
}


extension MusicXMLDocument.Measure.Attributes {
    
    public struct KeySignature: Equatable {
        public let octave: [Int]
        /// Indicates that the old key signature should be cancelled before the new one appears
        public let cancel: Bool
        /// The number of flats or sharps in a traditional key signature
        public let fifths: Int
        public let mode: Mode?
        
        static var none: KeySignature {
            KeySignature(octave: [], cancel: false, fifths: 0, mode: nil)
        }
        
        init(octave: [Int], cancel: Bool, fifths: Int, mode: Mode?) {
            self.octave = octave
            self.cancel = cancel
            self.fifths = fifths
            self.mode = mode
        }
        
        init(element: XMLElement) throws(ParseError) {
            assert(element.name == "key")
            
            var octave: [Int] = []
            try element.forEachChild(named: "octave") { (octaveElement) throws(ParseError) in
                try octave.append(octaveElement.asIntContainer())
            }
            self.octave = octave
            
            self.cancel = element.hasChild(named: "cancel")
            self.fifths = try element.withChild(named: "fifths", XMLElement.asIntContainer)
            self.mode = try element.withOptionalChild(named: "mode", XMLElement.asEnumContainer)
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
        
        init(element: XMLElement) throws(ParseError) {
            assert(element.name == "time")
            
            self.beats = try element.withChild(named: "beats", XMLElement.asIntContainer)
            self.beatType = try element.withChild(named: "beat-type", XMLElement.asIntContainer)
        }
    }
    
    public struct Clef {
        public let sign: Sign
        /// Standard values are 2 for the G sign (treble clef), 4 for the F sign (bass clef), and 3 for the C sign (alto clef)
        public let line: Int
        
        init(element: XMLElement) throws(ParseError) {
            assert(element.name == "clef")
            
            self.sign = try element.withChild(named: "sign", XMLElement.asEnumContainer)
            self.line = try element.withChild(named: "line", XMLElement.asIntContainer)
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
            descriptor.value(for: \.keySignature)
            descriptor.optional(for: \.staves)
            descriptor.value(for: \.clef)
        }
    }
    
}
