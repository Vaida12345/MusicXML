//
//  Measure + Utility.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-25.
//

import Foundation


extension MusicXMLDocument.Measure {
    
    /*
     <attributes><divisions> = how many divisions per quarter note
     <note><duration> = duration in divisions
     <backup><duration> = move current position backward
     <forward><duration> = move current position forward
     <chord/> = this note starts at the same time as the previous note, so do not advance before placing it
     */

    /// - Returns: onset of each individual note (`Note`) in local time (this measure) in divisions.
    public func makeNoteEventPositions() -> (totalTime: Int, mapping: [Int : Int]) {
        var localTime: Int = 0
        var results: [Int : Int] = [:]
        
        for content in self.contents {
            switch content {
            case .note(let note):
                if note.isChord {
                    localTime -= note.duration
                }
                
                results[note.id] = localTime
                localTime += note.duration
                
            case .backup(let duration):
                localTime -= duration
                
            case .forward(let duration):
                localTime += duration
                
            case .direction, .barline, .unknown:
                break
            }
        }
        
        return (localTime, results)
    }
    
    /// - Returns: Beam -> Chord -> Note
    public func aggregateNotes() -> [[[MusicXMLDocument.Note]]] {
        
        // first round, find beams
        var beams: [[MusicXMLDocument.Note]] = []
        var currentBeam: [MusicXMLDocument.Note] = []
        for content in self.contents {
            guard let note = content.as(.note) else { continue }
            guard note.pitch != nil else { continue } // is rest

            if note.isChord { currentBeam.append(note); continue } // must be in the same beam as previous
            let isStart = note.beams.allSatisfy({ $0 == .begin || $0 == .forwardHook })
            let isEnd = note.beams.allSatisfy({ $0 == .end || $0 == .backwardHook }) // or empty
            
            if isStart, !currentBeam.isEmpty {
                beams.append(currentBeam)
                currentBeam.removeAll()
            }
            
            currentBeam.append(note)
            
            if isEnd {
                beams.append(currentBeam)
                currentBeam.removeAll()
            }
            
            #if DEBUG
            if !isStart && !isEnd {
                assert(note.beams.contains(.continue))
            }
            #endif
        }
        if !currentBeam.isEmpty {
            beams.append(currentBeam)
        }
        assert(beams.map({ $0.count(where: { $0.pitch != nil }) }).sum == self.contents.count(where: { $0.as(.note)?.pitch != nil }))
        
        var result: [[[MusicXMLDocument.Note]]] = []
        for beam in beams {
            var chords: [[MusicXMLDocument.Note]] = []
            var currentChord: [MusicXMLDocument.Note] = []
            
            for note in beam {
                if note.isChord {
                    // connect with previous
                    currentChord.append(note)
                } else {
                    // end previous
                    if !currentChord.isEmpty {
                        chords.append(currentChord)
                    }
                    currentChord = [note]
                }
            }
            
            // end previous
            chords.append(currentChord)
            
            assert(chords.map(\.count).sum == beam.count)
            result.append(chords)
        }
        
        return result
    }
    
}
