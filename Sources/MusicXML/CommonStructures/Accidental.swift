//
//  Accidental.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//


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
