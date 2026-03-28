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

    /// - Returns: onset of each non-rest note (`Note`) in local time (this measure) in divisions.
    public func makeNoteEventPositions() -> (totalTime: Int, mapping: [Int : (onset: Int, note: MusicXMLDocument.Note)]) {
        var localTime: Int = 0
        var results: [Int : (onset: Int, note: MusicXMLDocument.Note)] = [:]
        
        for content in self.contents {
            switch content {
            case .note(let note):
                if note.isChord {
                    localTime -= note.duration ?? 0
                }
                
                if note.pitch != nil {
                    results[note.id] = (localTime, note)
                }
                localTime += note.duration ?? 0
                
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
        
        // first round, find chords
        var chords: [[MusicXMLDocument.Note]] = []
        var currentChord: [MusicXMLDocument.Note] = []
        
        for content in self.contents {
            guard let note = content.as(.note) else { continue }
            guard note.pitch != nil else { continue } // is rest
            
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
        
        if !currentChord.isEmpty {
            chords.append(currentChord)
        }
        assert(chords.map({ $0.count(where: { $0.pitch != nil }) }).sum == self.contents.count(where: { $0.as(.note)?.pitch != nil }))
        
        
        // second round, find beams
        var result: [[[MusicXMLDocument.Note]]] = []
        var currentBeam: [[MusicXMLDocument.Note]] = []
        for chord in chords {
            assert(chord.dropFirst().allSatisfy({ $0.beams.isEmpty })) // only the first one carry beam information.
            assert(!chord.isEmpty)
            
            let isStart = chord.first!.beams.allSatisfy({ $0 == .begin || $0 == .forwardHook })
            let isEnd = chord.first!.beams.allSatisfy({ $0 == .end || $0 == .backwardHook }) // or empty
            
            if isStart, !currentBeam.isEmpty {
                result.append(currentBeam)
                currentBeam.removeAll()
            }
            
            currentBeam.append(chord)
            
            if isEnd {
                result.append(currentBeam)
                currentBeam.removeAll()
            }
            
            #if DEBUG
            if !isStart && !isEnd {
                assert(chord.first!.beams.contains(.continue))
            }
            #endif
        }
        if !currentBeam.isEmpty {
            result.append(currentBeam)
        }
        
        return result
    }
    
}
