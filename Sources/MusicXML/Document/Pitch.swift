//
//  Pitch.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import AEXML


extension MusicXMLDocument.Note {

    /// Pitch is represented as a combination of the step of the diatonic scale, the chromatic alteration, and the octave.
    public struct Pitch: Equatable, Hashable {
        public let step: Step
        public let alteration: Double?
        /// 0 - 9
        public let octave: Int

        init(step: Step, alteration: Double?, octave: Int) {
            assert(0...9 ~= octave)
            self.step = step
            self.alteration = alteration
            self.octave = octave
        }

        init(element: AEXMLElement) throws(ParseError) {
            assert(element.name == "pitch")

            self.step = try element.withChild(named: "step", AEXMLElement.asEnumContainer)
            self.alteration = try element.withOptionalChild(named: "alter", AEXMLElement.asDoubleContainer)
            self.octave = try element.withChild(named: "octave", AEXMLElement.asIntContainer)
        }
        
        public func nextWhiteNote() -> Pitch {
            if let next = step.next {
                // same octave
                return Pitch(step: next, alteration: nil, octave: self.octave)
            } else {
                return Pitch(step: .C, alteration: nil, octave: self.octave + 1)
            }
        }
        
        public func previousWhiteNote() -> Pitch {
            if let previous = step.previous {
                // same octave
                return Pitch(step: previous, alteration: nil, octave: self.octave)
            } else {
                return Pitch(step: .B, alteration: nil, octave: self.octave - 1)
            }
        }

        public enum Step: String, CaseIterable, Hashable, Equatable {
            case A, B, C, D, E, F, G
            
            public var offset: Int {
                switch self {
                case .C: return 0
                case .D: return 2
                case .E: return 4
                case .F: return 5
                case .G: return 7
                case .A: return 9
                case .B: return 11
                }
            }
            
            var next: Step? {
                switch self {
                case .C: .D
                case .D: .E
                case .E: .F
                case .F: .G
                case .G: .A
                case .A: .B
                case .B: nil
                }
            }
            
            var previous: Step? {
                switch self {
                case .C: nil
                case .B: .A
                case .A: .G
                case .G: .F
                case .F: .E
                case .E: .D
                case .D: .C
                }
            }
        }
        
        public var midiPitch: Int {
            let offset = self.step.offset + Int(self.alteration ?? 0)
            return (octave + 1) * 12 + offset
        }
    }

}


extension MusicXMLDocument.Note.Pitch: CustomStringConvertible {
    public var description: String {
        if let alteration {
            switch alteration {
            case -2: step.rawValue + octave.description + "𝄫"
            case -1: step.rawValue + octave.description + "♭"
            case  1: step.rawValue + octave.description + "♯"
            case  2: step.rawValue + octave.description + "𝄪"
            default: step.rawValue + octave.description + " (" + alteration.description + ")"
            }
        } else {
            step.rawValue + octave.description
        }
    }
}
