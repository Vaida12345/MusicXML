//
//  Measure.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import DetailedDescription


extension MusicXMLDocument {
    
    /// Includes the basic musical data
    public struct Measure {
        
        /// The attribute that identifies the measure.
        public let number: String
        
        public let attributes: Attributes?
        
        public let notes: [Note]
        
        init(element: XMLElement) throws(ParseError) {
            assert(element.name == "measure")
            self.number = try element.attribute(named: "number", as: String.self)
            
            var notes: [Note] = []
            try element.forEachChild(named: "note") { (child) throws(ParseError) in
                guard let note = try Note(element: child) else { return } // ignore notes that dont produce a sound
                notes.append(note)
            }
            self.notes = notes
            
            self.attributes = try? element.withChild(named: "attributes", Attributes.init)
        }
        
    }
    
}


extension MusicXMLDocument.Measure: DetailedStringConvertible {
    
    public func detailedDescription(using descriptor: DetailedDescription.Descriptor<MusicXMLDocument.Measure>) -> any DescriptionBlockProtocol {
        descriptor.container("measure #\(number)") {
            descriptor.optional(for: \.attributes)
            descriptor.sequence(for: \.notes)
        }
    }
    
}
