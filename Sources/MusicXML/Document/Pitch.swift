//
//  Pitch.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation


extension MusicXMLDocument.Note {
    
    /// Pitch is represented as a combination of the step of the diatonic scale, the chromatic alteration, and the octave.
    public struct Pitch: Equatable, Hashable {
        let step: Step
        let alteration: Double?
        /// 0 - 9
        let octave: Int
        
        init(step: Step, alteration: Double?, octave: Int) {
            assert(0...9 ~= octave)
            self.step = step
            self.alteration = alteration
            self.octave = octave
        }
        
        init(element: XMLElement) throws(ParseError) {
            assert(element.name == "pitch")
            
            self.step = try element.withChild(named: "step", XMLElement.asEnumContainer)
            self.alteration = try element.withOptionalChild(named: "alter", XMLElement.asDoubleContainer)
            self.octave = try element.withChild(named: "octave", XMLElement.asIntContainer)
        }
        
        enum Step: String, CaseIterable {
            case A, B, C, D, E, F, G
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
