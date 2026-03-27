//
//  Note.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import AEXML
import DetailedDescription


extension MusicXMLDocument {

    public struct Note: Identifiable {
        /// Unique identifier for this note, assigned by this package. This is the offset of this content in measure.
        public let id: Int
        public let grace: Grace?
        /// Whether this note should be connected with the previous one to form a chord.
        public let isChord: Bool
        /// If `nil`, this is a rest.
        public let pitch: Pitch?
        /// Grace notes don't have duration.
        public let duration: Int?
        public let ties: [MusicXMLDocument.Measure.StartStop]
        public let voice: Int?
        public let type: NoteType?
        /// Number of dots
        public let dot: Int
        public let accidental: Accidental?
        public let timeModification: TimeModification?
        public let stem: MusicXMLDocument.Measure.VerticalDirection?
        /// 1 referring to the top-most staff
        public let staff: Int?
        /// Number of beams
        public let beams: [Beam]
        public let notations: Notations?


        init(id: Int, element: AEXMLElement) throws(ParseError) {
            self.id = id
            self.isChord = element.hasChild(named: "chord")
            self.grace = try element.withOptionalChild(named: "grace", Grace.init)
            self.pitch = try element.withOptionalChild(named: "pitch", Pitch.init)
            if self.grace == nil { // is not grace
                self.duration = try element.withChild(named: "duration", AEXMLElement.asIntContainer)
            } else {
                self.duration = nil
            }

            var tie: [MusicXMLDocument.Measure.StartStop] = []
            try element.forEachChild(named: "tie") { (child) throws(ParseError) in
                try tie.append(child.attribute(named: "type"))
            }
            self.ties = tie

            self.voice = try element.withOptionalChild(named: "voice", AEXMLElement.asIntContainer)
            self.type = try element.withOptionalChild(named: "type", AEXMLElement.asEnumContainer)
            self.dot = element.children.count(where: { $0.name == "dot" })
            self.accidental = try element.withOptionalChild(named: "accidental", AEXMLElement.asEnumContainer)
            self.timeModification = try element.withOptionalChild(named: "time-modification", TimeModification.init)
            self.stem = try element.withOptionalChild(named: "stem", AEXMLElement.asEnumContainer)
            self.staff = try element.withOptionalChild(named: "staff", AEXMLElement.asIntContainer)

            var beam: [Beam] = []
            try element.forEachChild(named: "beam") { (child) throws(ParseError) in
                try beam.append(child.asEnumContainer())
            }
            self.beams = beam

            self.notations = try element.withOptionalChild(named: "notations", Notations.init)
        }


        public struct TimeModification {
            /// Describes how many notes are played in the time usually occupied by ``normal``.
            public let actual: Int
            /// Normal notes count.
            public let normal: Int

            init(element: AEXMLElement) throws(ParseError) {
                assert(element.name == "time-modification")
                self.actual = try element.withChild(named: "actual-notes", AEXMLElement.asIntContainer)
                self.normal = try element.withChild(named: "normal-notes", AEXMLElement.asIntContainer)
            }
        }
        
        public enum Accidental: String, CaseIterable {
            case sharp
            case natural
            case flat
            case doubleSharp = "double-sharp"
            case doubleFlat = "double-flat"
            case sharpSharp = "sharp-sharp"
            case flatFlat = "flat-flat"
            case naturalSharp = "natural-sharp"
            case naturalFlat = "natural-flat"
        }
        
        public struct Grace: Sendable, Hashable {
            public var hasSlash: Bool
            
            public init(hasSlash: Bool) {
                self.hasSlash = hasSlash
            }
            
            init(element: AEXMLElement) throws(ParseError) {
                assert(element.name == "grace")
                self.hasSlash = element.hasChild(named: "slash")
            }
        }
        
        public struct Notations: DetailedStringConvertible {
            public let arpeggiate: Arpeggiate?
            public let glissando: Glissando?
            
            init(element: AEXMLElement) throws(ParseError) {
                assert(element.name == "notations")
                
                self.arpeggiate = try element.withOptionalChild(named: "arpeggiate", Arpeggiate.init)
                self.glissando = try element.withOptionalChild(named: "glissando", Glissando.init)
            }
            
            public struct Arpeggiate {
                /// Identifier.
                public let number: Int?
                
                init(element: AEXMLElement) throws(ParseError) {
                    assert(element.name == "arpeggiate")
                    
                    self.number = try? element.attribute(named: "number")
                }
            }
            
            public struct Glissando {
                public let type: MusicXMLDocument.Measure.StartStop
                /// Distinguishes multiple glissandos when they overlap in MusicXML document order. 
                public let number: Int?
                
                init(element: AEXMLElement) throws(ParseError) {
                    assert(element.name == "glissando")
                    
                    self.type = try element.attribute(named: "type", as: MusicXMLDocument.Measure.StartStop.self)
                    self.number = try? element.attribute(named: "number")
                }
            }
            
            public func detailedDescription(using descriptor: DetailedDescription.Descriptor<MusicXMLDocument.Note.Notations>) -> any DescriptionBlockProtocol {
                descriptor.container {
                    descriptor.optional(for: \.arpeggiate)
                    descriptor.optional(for: \.glissando)
                }
            }
        }


    }

}


extension MusicXMLDocument.Note: DetailedStringConvertible {

    public func detailedDescription(using descriptor: DetailedDescription.Descriptor<MusicXMLDocument.Note>) -> any DescriptionBlockProtocol {
        descriptor.container(self.pitch?.description ?? "rest") {
            if self.isChord {
                descriptor.constant("chord")
            }
            descriptor.optional(for: \.grace)
            descriptor.optional(for: \.duration)
            descriptor.value(for: \.ties)
                .serialized()
            descriptor.optional(for: \.voice)
            descriptor.optional(for: \.type)
            if dot != 0 {
                descriptor.value(for: \.dot)
            }
            descriptor.optional(for: \.accidental)
            descriptor.optional(for: \.timeModification)
            descriptor.optional(for: \.stem)
            descriptor.optional(for: \.staff)
            descriptor.value(for: \.beams)
                .serialized()
            descriptor.optional(for: \.notations)
        }
        .hideEmptySequence()
    }

}
