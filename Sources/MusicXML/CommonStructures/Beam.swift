//
//  Beam.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//


extension MusicXMLDocument.Note {
    
    public enum Beam: String, CaseIterable {
        case backwardHook = "backward hook"
        case begin
        case `continue`
        case end
        case forwardHook = "forward hook"
    }

}
