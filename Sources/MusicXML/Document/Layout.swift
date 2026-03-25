//
//  Layout.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-25.
//

import AEXML


extension MusicXMLDocument {
    
    public struct Layout {
        
        public let pageWidth: Double?
        
        init(root: AEXMLElement) throws(ParseError) {
            self.pageWidth = try root.withOptionalChild(named: "defaults") { defaults throws(ParseError) in
                try defaults.withOptionalChild(named: "page-layout") { layout throws(ParseError) in
                    try layout.withOptionalChild(named: "page-width", AEXMLElement.asDoubleContainer)
                }
            }
        }
        
    }
    
}
