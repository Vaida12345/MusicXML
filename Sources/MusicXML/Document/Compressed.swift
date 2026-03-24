//
//  Compressed.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import ZIPFoundation

enum MXLDecodeError: Error {
    case missingContainerXML
    case missingRootfilePath
    case missingRootfileEntry(String)
}

func decodeMXL(data: Data) throws -> XMLDocument {
    let archive = try Archive(data: data, accessMode: .read)
    
    // 1) Read META-INF/container.xml to discover the root MusicXML file
    guard let containerEntry = archive["META-INF/container.xml"] else {
        throw MXLDecodeError.missingContainerXML
    }
    
    let containerData = try extract(entry: containerEntry, from: archive)
    let containerDoc = try XMLDocument(data: containerData, options: [])
    
    // container.xml contains something like:
    // <rootfile full-path="score.xml" media-type="application/vnd.recordare.musicxml+xml"/>
    let rootfilePath = try findRootfileFullPath(in: containerDoc)
    guard let rootEntry = archive[rootfilePath] else {
        throw MXLDecodeError.missingRootfileEntry(rootfilePath)
    }
    
    // 2) Extract the actual MusicXML file and parse
    let musicXMLData = try extract(entry: rootEntry, from: archive)
    return try XMLDocument(data: musicXMLData, options: [])
}

private func extract(entry: Entry, from archive: Archive) throws -> Data {
    var data = Data()
    _ = try archive.extract(entry) { chunk in
        data.append(chunk)
    }
    return data
}

private func findRootfileFullPath(in containerDoc: XMLDocument) throws -> String {
    // Simple XPath; works with typical container.xml (ignores namespaces).
    // If your container.xml uses default namespaces, you may need namespace-aware XPath.
    let nodes = try containerDoc.nodes(forXPath: "//*[local-name()='rootfile']/@full-path")
    if let attr = nodes.first, let path = attr.stringValue, !path.isEmpty {
        return path
    }
    throw MXLDecodeError.missingRootfilePath
}
