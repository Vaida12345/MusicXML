//
//  XMLNode.Kind.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation


extension XMLNode.Kind: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalid: "invalid"
        case .document: "document"
        case .element: "element"
        case .attribute: "attribute"
        case .namespace: "namespace"
        case .processingInstruction: "processingInstruction"
        case .comment: "comment"
        case .text: "text"
        case .DTDKind: "DTDKind"
        case .entityDeclaration: "entityDeclaration"
        case .attributeDeclaration: "attributeDeclaration"
        case .elementDeclaration: "elementDeclaration"
        case .notationDeclaration: "notationDeclaration"
        @unknown default: "unknown"
        }
    }
}
