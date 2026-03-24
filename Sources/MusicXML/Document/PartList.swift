//
//  PartList.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation


extension MusicXMLDocument {
    
    public struct PartList {
        
        
        public struct Element {
            public let id: String
            public let name: String
            
            
            init(node: XMLNode) throws(ParseError) {
                let element = try node.asElement()
                let scorePart = try element.child(named: "score-part")
                do {
                    let scorePart = try scorePart.asElement()
                    self.id = try scorePart.attribute(named: "id", as: String.self)
                    
                    let name = try scorePart.child(named: "part-name")
                    do {
                        self.name = try name.asTextContainer()
                    } catch {
                        throw ParseError.childNodeError(name: "part-name", error: error)
                    }
                } catch {
                    throw ParseError.childNodeError(name: "score-part", error: error as! ParseError)
                }
            }
        }
    }
    
}
