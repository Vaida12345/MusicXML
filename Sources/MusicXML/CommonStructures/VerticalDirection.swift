//
//  Direction.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//


extension MusicXMLDocument.Measure {
    public enum VerticalDirection: String, CaseIterable, CustomStringConvertible, Sendable, Hashable, BitwiseCopyable {
        case up, down
        
        public var description: String {
            switch self {
            case .up: ".up"
            case .down: ".down"
            }
        }
    }
    
    public enum HorizontalDirection: String, CaseIterable, CustomStringConvertible, Sendable, Hashable, BitwiseCopyable {
        case forward, backward
        
        public var description: String {
            switch self {
            case .forward: ".forward"
            case .backward: ".backward"
            }
        }
    }
}
