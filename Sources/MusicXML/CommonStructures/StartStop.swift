//
//  StartStop.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//


extension MusicXMLDocument.Measure {
    public enum StartStop: String, CaseIterable {
        case start, stop
    }
    
    public enum StartStopContinue: String, CaseIterable {
        case start, stop, `continue`
    }
    
    
    public enum StartStopDiscontinue: String, CaseIterable {
        case start, stop, discontinue
    }
}
