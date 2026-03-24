//
//  Note.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import DetailedDescription


extension MusicXMLDocument {
    
    public struct Note {
        
        public let isChord: Bool
        public let pitch: Pitch
        public let duration: Int
        public let ties: [StartStop]
        public let voice: Int?
        public let type: NoteType?
        /// Number of dots
        public let dot: Int
        public let accidental: Accidental?
        public let timeModification: TimeModification?
        public let stem: VerticalDirection?
        public let staff: Int?
        /// Number of beams
        public let beams: [Beam]
        
        
        /// Returns `nil` when self does not produce a sound.
        init?(element: XMLElement) throws(ParseError) {
            guard !element.hasChild(named: "rest") else { return nil }
            self.isChord = element.hasChild(named: "chord")
            self.pitch = try element.withChild(named: "pitch", Pitch.init)
            self.duration = try element.withChild(named: "duration", XMLElement.asIntContainer)
            
            var tie: [StartStop] = []
            try element.forEachChild(named: "tie") { (child) throws(ParseError) in
                try tie.append(child.attribute(named: "type"))
            }
            self.ties = tie
            
            self.voice = try element.withOptionalChild(named: "voice", XMLElement.asIntContainer)
            self.type = try element.withOptionalChild(named: "type", XMLElement.asEnumContainer)
            self.dot = (element.children ?? []).count(where: { $0.name == "dot" })
            self.accidental = try element.withOptionalChild(named: "accidental", XMLElement.asEnumContainer)
            self.timeModification = try element.withOptionalChild(named: "time-modification", TimeModification.init)
            self.stem = try element.withOptionalChild(named: "stem", XMLElement.asEnumContainer)
            self.staff = try element.withOptionalChild(named: "staff", XMLElement.asIntContainer)
            
            var beam: [Beam] = []
            try element.forEachChild(named: "beam") { (child) throws(ParseError) in
                try beam.append(child.asEnumContainer())
            }
            self.beams = beam
            
            // notations are ignored.
        }
        
        
        public struct TimeModification {
            /// Describes how many notes are played in the time usually occupied by ``normal``.
            let actual: Int
            /// Normal notes count.
            let normal: Int
            
            init(element: XMLElement) throws(ParseError) {
                assert(element.name == "time-modification")
                self.actual = try element.withChild(named: "actual-notes", XMLElement.asIntContainer)
                self.normal = try element.withChild(named: "normal-notes", XMLElement.asIntContainer)
            }
        }
        
    }
    
}


extension MusicXMLDocument.Note: DetailedStringConvertible {
    
    public func detailedDescription(using descriptor: DetailedDescription.Descriptor<MusicXMLDocument.Note>) -> any DescriptionBlockProtocol {
        descriptor.container(self.pitch.description) {
            if self.isChord {
                descriptor.constant("chord")
            }
            descriptor.value(for: \.duration)
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
        }
        .hideEmptySequence()
    }
    
}
