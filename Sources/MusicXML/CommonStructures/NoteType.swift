//
//  NoteType.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

extension MusicXMLDocument.Note {
    public enum NoteType: String, CaseIterable {
        case oneThousandTwentyFourth = "1024th"
        case fiveHundredTwelfth = "512th"
        case twoHundredFiftySixth = "256th"
        case hundredTwentyEighth = "128th"
        case sixtyFourth = "64th"
        case thirtySecond = "32nd"
        case sixteenth = "16th"
        case eighth = "eighth"
        case quarter = "quarter"
        case half = "half"
        case whole = "whole"
        case double = "breve"
        case long = "long"
        case maxima = "maxima"
    }
}
