import Foundation
import AEXML
import FinderItem
import ZIPFoundation

extension MusicXMLDocument {
    public enum ExportFormat: String, CaseIterable, Sendable {
        /// ZIP-compressed MusicXML with a container manifest.
        case mxl
        /// Uncompressed UTF-8 MusicXML.
        case musicXML
    }

    /// Generates a partwise score and atomically replaces the destination file.
    ///
    /// The format is explicit and independent of the destination's extension.
    /// Unknown name-only placeholders are omitted. Values are exported without validation.
    public func write(to destination: FinderItem, format: ExportFormat = .mxl) throws {
        let xml = Data(xmlDocument.xml.utf8)
        switch format {
        case .musicXML:
            try xml.write(to: destination)
        case .mxl:
            try encodeMXL(xml: xml).write(to: destination)
        }
    }

    private var xmlDocument: AEXMLDocument {
        let root = AEXMLElement(name: "score-partwise")
        root.setAttribute("version", version ?? "4.0")
        if let title { root.addChild(name: "work").addValue("work-title", title) }
        if composer != nil || !encodingSoftware.isEmpty {
            let identification = root.addChild(name: "identification")
            if let composer {
                identification.addChild(name: "creator", value: composer, attributes: ["type": "composer"])
            }
            if !encodingSoftware.isEmpty {
                let encoding = identification.addChild(name: "encoding")
                for software in encodingSoftware { encoding.addValue("software", software) }
            }
        }
        let defaults = layout.xmlElement
        if !defaults.children.isEmpty { root.addChild(defaults) }
        for credit in credits { root.addChild(credit.xmlElement) }
        root.addChild(partList.xmlElement)
        for part in parts { root.addChild(part.xmlElement) }
        return AEXMLDocument(root: root)
    }
}

private func encodeMXL(xml: Data) throws -> Data {
    let archive = try Archive(accessMode: .create)
    let container = AEXMLElement(name: "container")
    container.addChild(name: "rootfiles").addChild(name: "rootfile", attributes: [
        "full-path": "score.musicxml",
        "media-type": "application/vnd.recordare.musicxml+xml"
    ])
    // MusicXML requires the first entry to be an uncompressed, whitespace-free MIME type.
    try addArchiveEntry("mimetype", data: Data("application/vnd.recordare.musicxml".utf8), to: archive, compression: .none)
    try addArchiveEntry("META-INF/container.xml", data: Data(AEXMLDocument(root: container).xml.utf8), to: archive)
    try addArchiveEntry("score.musicxml", data: xml, to: archive)
    guard let data = archive.data else { throw Archive.ArchiveError.unwritableArchive }
    return data
}

private func addArchiveEntry(_ path: String, data: Data, to archive: Archive, compression: CompressionMethod = .deflate) throws {
    try archive.addEntry(with: path, type: .file, uncompressedSize: Int64(data.count), compressionMethod: compression) { position, size in
        data.subdata(in: Int(position)..<(Int(position) + size))
    }
}

extension MusicXMLDocument.PartList {
    var xmlElement: AEXMLElement {
        let element = AEXMLElement(name: "part-list")
        for part in self {
            let score = element.addChild(name: "score-part", attributes: ["id": part.id])
            score.addValue("part-name", part.name)
            if let instrument = part.instrument {
                score.addChild(name: "score-instrument", attributes: ["id": part.id + "-I1"]).addValue("instrument-name", instrument)
            }
        }
        return element
    }
}

extension MusicXMLDocument.Part {
    var xmlElement: AEXMLElement {
        let element = AEXMLElement(name: "part", attributes: ["id": id])
        for measure in measures { element.addChild(measure.xmlElement) }
        return element
    }
}

extension MusicXMLDocument.Measure {
    var xmlElement: AEXMLElement {
        let element = AEXMLElement(name: "measure", attributes: ["number": number])
        // Printing instructions normally precede attributes at the beginning of a measure.
        let leadingPrints = contents.prefix { if case .print = $0 { return true }; return false }
        for content in leadingPrints { if case .print(let print) = content { element.addChild(print.xmlElement) } }
        if let attributes { element.addChild(attributes.xmlElement) }
        for content in contents.dropFirst(leadingPrints.count) {
            switch content {
            case .note(let note): element.addChild(note.xmlElement)
            case .backup(let duration): element.addChild(name: "backup").addValue("duration", duration)
            case .forward(let duration): element.addChild(name: "forward").addValue("duration", duration)
            case .barline(let barline): element.addChild(barline.xmlElement)
            case .direction(let direction): element.addChild(direction.xmlElement)
            case .print(let print): element.addChild(print.xmlElement)
            case .unknown: continue
            }
        }
        return element
    }
}

extension MusicXMLDocument.Measure.Attributes {
    var xmlElement: AEXMLElement {
        let element = AEXMLElement(name: "attributes")
        element.addValue("divisions", divisions)
        if let keySignature { element.addChild(keySignature.xmlElement) }
        if let timeSignature {
            let time = element.addChild(name: "time")
            time.addValue("beats", timeSignature.beats)
            time.addValue("beat-type", timeSignature.beatType)
        }
        element.addValue("staves", staves)
        for clef in clefs {
            let clefElement = element.addChild(name: "clef")
            clefElement.setAttribute("number", clef.number)
            clefElement.addEnum("sign", clef.sign)
            clefElement.addValue("line", clef.line)
        }
        return element
    }
}

extension MusicXMLDocument.Measure.Attributes.KeySignature {
    var xmlElement: AEXMLElement {
        let element = AEXMLElement(name: "key")
        // The current model retains only whether cancellation is requested, not its original fifths.
        if cancel { element.addValue("cancel", 0) }
        switch value {
        case .none: element.addValue("fifths", 0)
        case .traditional(let fifths, let mode):
            element.addValue("fifths", fifths)
            element.addEnum("mode", mode)
        case .nonTraditional(let values):
            for value in values {
                element.addEnum("key-step", value.step)
                element.addValue("key-alter", value.alter)
            }
        }
        for (index, octave) in octave.enumerated() {
            element.addChild(name: "key-octave", value: String(octave), attributes: ["number": String(index + 1)])
        }
        return element
    }
}

extension MusicXMLDocument.Note {
    var xmlElement: AEXMLElement {
        let element = AEXMLElement(name: "note")
        element.setAttribute("dynamics", dynamics)
        if let grace {
            element.addChild(name: "grace", attributes: ["slash": grace.hasSlash ? "yes" : "no"])
        }
        if isChord { element.addChild(name: "chord") }
        if let pitch {
            let pitchElement = element.addChild(name: "pitch")
            pitchElement.addEnum("step", pitch.step)
            pitchElement.addValue("alter", pitch.alteration)
            pitchElement.addValue("octave", pitch.octave)
        } else if let unpitched {
            element.addChild(unpitched.xmlElement)
        } else {
            let rest = element.addChild(name: "rest")
            if isMeasureRest { rest.setYesNoAttribute("measure", true) }
        }
        if grace == nil { element.addValue("duration", duration) }
        // Stop precedes start on a note tied on both sides.
        for tie in [MusicXMLDocument.Measure.StartStop.stop, .start] where ties.contains(tie) {
            element.addChild(name: "tie", attributes: ["type": tie.rawValue])
        }
        element.addValue("voice", voice)
        element.addEnum("type", type)
        element.addRepeated("dot", count: dot)
        element.addEnum("accidental", accidental)
        if let timeModification {
            let modification = element.addChild(name: "time-modification")
            modification.addValue("actual-notes", timeModification.actual)
            modification.addValue("normal-notes", timeModification.normal)
        }
        if let stem {
            let stemElement = element.addChild(name: "stem", value: stem.rawValue)
            stemGeometry?.apply(to: stemElement)
        }
        if let noteheadText { element.addChild(noteheadText.xmlElement) }
        element.addValue("staff", staff)
        for (index, beam) in beams.enumerated() {
            element.addChild(name: "beam", value: beam.rawValue, attributes: ["number": String(index + 1)])
        }
        if notations != nil || !ties.isEmpty {
            let notation = element.addChild(name: "notations")
            // Playback ties and their visible counterparts are generated from the same model value.
            for tie in [MusicXMLDocument.Measure.StartStop.stop, .start] where ties.contains(tie) {
                notation.addChild(name: "tied", attributes: ["type": tie.rawValue])
            }
            if let notations {
                for child in notations.xmlElement.children { notation.addChild(child) }
            }
        }
        for lyric in lyrics { element.addChild(lyric.xmlElement) }
        return element
    }
}

extension MusicXMLDocument.Measure.BarLine {
    var xmlElement: AEXMLElement {
        let element = AEXMLElement(name: "barline")
        if let ending {
            element.addChild(name: "ending", attributes: ["number": ending.number.map(String.init).joined(separator: ","), "type": ending.type.rawValue])
        }
        if let `repeat` {
            element.addChild(name: "repeat", attributes: ["direction": `repeat`.direction.rawValue])
        }
        return element
    }
}
