//
//  StartStop.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//


extension MusicXMLDocument.Measure {
    public enum StartStop: String, CaseIterable, Hashable, Sendable, BitwiseCopyable {
        case start, stop
    }
    
    public enum StartStopContinue: String, CaseIterable, Hashable, Sendable, BitwiseCopyable {
        case start, stop, `continue`
    }
    
    
    public enum StartStopDiscontinue: String, CaseIterable, Hashable, Sendable, BitwiseCopyable {
        case start, stop, discontinue
    }
}
