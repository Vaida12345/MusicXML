//
//  Compressed.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import AEXML
import ZIPFoundation

enum MXLDecodeError: Error {
    case missingContainerXML
    case missingRootfilePath
    case missingRootfileEntry(String)
}

func decodeMXL(data: Data) throws -> AEXMLDocument {
    let archive = try Archive(data: data, accessMode: .read)

    // 1) Read META-INF/container.xml to discover the root MusicXML file
    guard let containerEntry = archive["META-INF/container.xml"] else {
        throw MXLDecodeError.missingContainerXML
    }

    let containerData = try extract(entry: containerEntry, from: archive)
    let containerDoc = try AEXMLDocument(xml: containerData)

    // container.xml contains something like:
    // <rootfile full-path="score.xml" media-type="application/vnd.recordare.musicxml+xml"/>
    let rootfilePath = try findRootfileFullPath(in: containerDoc)
    guard let rootEntry = archive[rootfilePath] else {
        throw MXLDecodeError.missingRootfileEntry(rootfilePath)
    }

    // 2) Extract the actual MusicXML file and parse
    let musicXMLData = try extract(entry: rootEntry, from: archive)
    return try AEXMLDocument(xml: musicXMLData)
}

private func extract(entry: Entry, from archive: Archive) throws -> Data {
    var data = Data()
    _ = try archive.extract(entry) { chunk in
        data.append(chunk)
    }
    return data
}

private func findRootfileFullPath(in containerDoc: AEXMLDocument) throws -> String {
    if let path = findRootfileElement(in: containerDoc.root)?.attributes["full-path"], !path.isEmpty {
        return path
    }
    throw MXLDecodeError.missingRootfilePath
}

private func findRootfileElement(in element: AEXMLElement) -> AEXMLElement? {
    if localName(of: element.name) == "rootfile" {
        return element
    }

    for child in element.children {
        if let result = findRootfileElement(in: child) {
            return result
        }
    }
    return nil
}

private func localName(of qualifiedName: String) -> String {
    if let colonIndex = qualifiedName.lastIndex(of: ":") {
        return String(qualifiedName[qualifiedName.index(after: colonIndex)...])
    }
    return qualifiedName
}
