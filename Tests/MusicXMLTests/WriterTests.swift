import Testing
import Foundation
import AEXML
import ZIPFoundation
import FinderItem
import MusicXML

typealias Score = MusicXMLDocument
typealias Note = Score.Note
typealias Measure = Score.Measure

/// These fixtures are constructed through the public API, without importing an existing score.
private func generatedScore(title: String = "Piano & <Study>") -> Score {
    let layout = Score.Layout(
        pageWidth: 1200, pageHeight: 1600,
        pageMargins: [.init(left: 80, right: 80, top: 100, bottom: 100, type: .both)],
        scaling: .init(millimeters: 7, tenths: 40),
        system: .init(margins: .init(left: 10, right: 0), distance: 120, topDistance: 160),
        staves: [.init(number: 2, distance: 70)],
        appearance: .init(lineWidths: [.init(type: "staff", width: 1)], noteSizes: [.init(type: .grace, size: 60)]),
        musicFont: .init(family: "Bravura", size: 20),
        wordFont: .init(family: "Times New Roman", size: 12, style: .italic),
        lyricFont: .init(family: "Times New Roman", size: 10)
    )
    let direction = Measure.Direction(contents: [
        .words(.init("dolce & cantabile", font: .init(style: .italic))),
        .rehearsal(.init("A", font: .init(weight: .bold))),
        .segno, .coda,
        .pedal(.init(type: .start, number: 1, line: true, sign: false)),
        .bracket(.init(type: .start, lineEnd: .down, number: 1, lineType: .dashed, endLength: 10)),
        .metronome(.init(beatUnit: .quarter, dots: 1, rhs: .perMinute(80))),
        .octaveShift(.init(phase: .start, shift: 1, number: 1)),
        .wedge(.init(type: .crescendo)),
        .dynamics(.init(values: ["p"])),
        .dashes(.init(type: .start, value: .rit, number: 1))
    ], sound: .init(tempo: 80, dynamics: 60), staff: 1, placement: .above, voice: 1, offset: 0)
    let note = Note(id: 2, pitch: .init(step: .C, alteration: 1, octave: 4), duration: 4,
                    ties: [.stop, .start], voice: 1, type: .quarter, dot: 1, accidental: .sharp,
                    timeModification: .init(actual: 3, normal: 2), stem: .up, staff: 1, beams: [.begin, .forwardHook],
                    notations: .init(arpeggiations: [.init(number: 1), .init(number: 2)],
                                     glissandos: [.init(type: .start, number: 1), .init(type: .stop, number: 2)],
                                     slurs: [.init(type: .start, number: 1, placement: .above, lineType: .solid)],
                                     articulations: [.init(.staccato, placement: .below), .init(.accent)],
                                     ornaments: [.init(.trillMark), .init(.tremolo, tremoloType: .single, value: "3")],
                                     tuplets: [.init(type: .start, number: 1, bracket: true, placement: .above, showNumber: .both,
                                                     actual: .init(number: 3, type: .eighth, dots: 1), normal: .init(number: 2, type: .eighth))]),
                    lyrics: [.init(text: "la & <la>", syllabic: .begin, extend: .start, number: "1", placement: .below)])
    let measure = Measure(number: "1", attributes: .init(divisions: 4, keySignature: .init(value: .traditional(fifths: 1, mode: .major)),
                                                          timeSignature: .init(beats: 4, beatType: 4), staves: 2, clef: .init(sign: .treble, line: 2)), contents: [
        .print(.init(newSystem: true, newPage: true, pageNumber: "2", blankPages: 1,
                     pageLayout: .init(width: 1200, height: 1600, margins: [.init(left: 90, right: 80, top: 100, bottom: 100, type: .odd)]),
                     systemLayout: .init(distance: 140), staffLayouts: [.init(number: 2, distance: 80)], measureDistance: 20, measureNumbering: .system)),
        .direction(direction), .note(note),
        .note(.init(id: 3, grace: .init(hasSlash: true), pitch: .init(step: .D, octave: 4), type: .eighth)),
        .backup(duration: 4),
        .note(.init(id: 5, duration: 16, voice: 2, staff: 2, isMeasureRest: true)),
        .forward(duration: 1),
        .note(.init(id: 7, duration: 1, type: .sixteenth, unpitched: .init(displayStep: .C, displayOctave: 5))),
        .barline(.init(ending: .init(number: [1, 2], type: .start), repeat: .init(direction: .backward))),
        .unknown("harmony")
    ])
    return Score(layout: layout, partList: .init(scores: [.init(id: "P1", name: "Piano", instrument: "Grand Piano")]),
                 parts: [.init(id: "P1", measures: [measure])], title: title, composer: "A & B",
                 credits: [.init(page: 1, types: ["title"], words: [.init(title, font: .init(size: 22, weight: .bold),
                                                                        defaultX: 600, defaultY: 1500, justify: .center, verticalAlignment: .top)])])
}

private func withDestination<T>(_ body: (FinderItem) throws -> T) throws -> T {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MusicXMLTests-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    return try body(FinderItem(at: folder.appendingPathComponent("score.output").path))
}

private func extract(_ entry: Entry, from archive: Archive) throws -> Data {
    var data = Data()
    _ = try archive.extract(entry) { data.append($0) }
    return data
}

private func exportedXML(_ score: Score, format: Score.ExportFormat = .musicxml) throws -> AEXMLDocument {
    try withDestination { destination in
        try score.write(to: destination, format: format)
        let data = try Data(contentsOf: destination.url)
        if format == .musicxml { return try AEXMLDocument(xml: data) }
        let archive = try Archive(data: data, accessMode: .read)
        return try AEXMLDocument(xml: extract(try #require(archive["score.musicxml"]), from: archive))
    }
}

@Suite struct WriterTests {
    @Test(arguments: Score.ExportFormat.allCases)
    func generatesBothFormats(format: Score.ExportFormat) throws {
        let root = try exportedXML(generatedScore(), format: format).root
        #expect(root.name == "score-partwise")
        #expect(root.attributes["version"] == "4.0")
        #expect(root["work"]["work-title"].value == "Piano & <Study>")
        #expect(root["identification"]["creator"].value == "A & B")
        #expect(root["part-list"]["score-part"]["score-instrument"].attributes["id"] == "P1-I1")
        #expect(root["part"].attributes["id"] == "P1")
        #expect(root.children.map(\.name) == ["work", "identification", "defaults", "credit", "part-list", "part"])
    }

    @Test func defaultFormatIsCompressed() throws {
        try withDestination { destination in
            try generatedScore().write(to: destination)
            let data = try Data(contentsOf: destination.url)
            #expect(data.starts(with: [0x50, 0x4B]))
            let archive = try Archive(data: data, accessMode: .read)
            #expect(archive.map(\.path) == ["mimetype", "META-INF/container.xml", "score.musicxml"])
            let mime = try extract(#require(archive["mimetype"]), from: archive)
            #expect(mime == Data("application/vnd.recordare.musicxml".utf8))
            // ZIP local header: compression method = 0, extra-field length = 0.
            #expect(Array(data[8..<10]) == [0, 0])
            #expect(Array(data[28..<30]) == [0, 0])
            let container = try AEXMLDocument(xml: extract(#require(archive["META-INF/container.xml"]), from: archive))
            #expect(container.root["rootfiles"]["rootfile"].attributes["full-path"] == "score.musicxml")
            #expect(container.root["rootfiles"]["rootfile"].attributes["media-type"] == "application/vnd.recordare.musicxml+xml")
        }
    }

    @Test func layoutAndCredits() throws {
        let root = try exportedXML(generatedScore()).root
        let defaults = root["defaults"]
        #expect(defaults["page-layout"].children.map(\.name) == ["page-height", "page-width", "page-margins"])
        #expect(defaults["page-layout"]["page-height"].double == 1600)
        #expect(defaults["scaling"]["millimeters"].double == 7)
        #expect(defaults["system-layout"]["system-margins"]["left-margin"].double == 10)
        #expect(defaults["staff-layout"].attributes["number"] == "2")
        #expect(defaults["appearance"]["note-size"].double == 60)
        #expect(defaults["word-font"].attributes["font-style"] == "italic")
        #expect(root["credit"].attributes["page"] == "1")
        #expect(root["credit"]["credit-words"].attributes["justify"] == "center")
        let measure = root["part"]["measure"]
        #expect(measure.children.prefix(2).map(\.name) == ["print", "attributes"])
        #expect(measure["print"].attributes["new-page"] == "yes")
        #expect(measure["print"]["measure-numbering"].value == "system")
        #expect(measure["print"]["staff-layout"]["staff-distance"].double == 80)
    }

    @Test func notesAndNotations() throws {
        let measure = try exportedXML(generatedScore()).root["part"]["measure"]
        let notes = measure.children.filter { $0.name == "note" }
        let note = try #require(notes.first)
        #expect(note["pitch"]["alter"].double == 1)
        #expect(note.children.filter { $0.name == "tie" }.map { $0.attributes["type"] } == ["stop", "start"])
        #expect(note.children.filter { $0.name == "beam" }.map { $0.attributes["number"] } == ["1", "2"])
        let notation = note["notations"]
        #expect(notation.children.filter { $0.name == "tied" }.count == 2)
        #expect(notation.children.filter { $0.name == "arpeggiate" }.count == 2)
        #expect(notation.children.filter { $0.name == "glissando" }.count == 2)
        #expect(notation["slur"].attributes["placement"] == "above")
        #expect(notation["articulations"]["staccato"].attributes["placement"] == "below")
        #expect(notation["ornaments"]["tremolo"].value == "3")
        #expect(notation["tuplet"]["tuplet-actual"]["tuplet-number"].int == 3)
        #expect(note["lyric"]["text"].value == "la & <la>")
        #expect(notes[1]["grace"].attributes["slash"] == "yes")
        #expect(!notes[1].children.contains { $0.name == "duration" })
        #expect(notes[2]["rest"].attributes["measure"] == "yes")
        #expect(notes[3]["unpitched"]["display-octave"].int == 5)
        #expect(!measure.children.contains { $0.name == "harmony" })
        #expect(measure["barline"]["ending"].attributes["number"] == "1,2")
    }

    @Test func directions() throws {
        let direction = try exportedXML(generatedScore()).root["part"]["measure"]["direction"]
        #expect(direction.attributes["placement"] == "above")
        #expect(direction["offset"].double == 0)
        #expect(direction["voice"].int == 1)
        #expect(direction["staff"].int == 1)
        #expect(direction["sound"].attributes["tempo"] == "80")
        let types = direction.children.filter { $0.name == "direction-type" }.flatMap(\.children)
        #expect(types.map(\.name) == ["words", "rehearsal", "segno", "coda", "pedal", "bracket", "metronome", "octave-shift", "wedge", "dynamics", "words", "dashes"])
        #expect(types.first { $0.name == "pedal" }?.attributes["line"] == "yes")
        #expect(types.first { $0.name == "bracket" }?.attributes["line-end"] == "down")
        #expect(types.first { $0.name == "octave-shift" }?.attributes["size"] == "8")
    }

    @Test(arguments: Score.ExportFormat.allCases)
    func readerUnderstandsGeneratedFeatures(format: Score.ExportFormat) throws {
        try withDestination { destination in
            try generatedScore().write(to: destination, format: format)
            let score = try Score(data: Data(contentsOf: destination.url))
            #expect(score.title == "Piano & <Study>")
            #expect(score.layout.pageHeight == 1600)
            #expect(score.credits.first?.words.first?.font?.size == 22)
            let measure = try #require(score.parts.first?.measures.first)
            #expect(measure.contents.first?.as(.print)?.newPage == true)
            let notes = measure.contents.compactMap { $0.as(.note) }
            #expect(notes[0].notations?.arpeggiations.count == 2)
            #expect(notes[0].notations?.glissandos.count == 2)
            #expect(notes[0].notations?.slurs.count == 1)
            #expect(notes[0].notations?.articulations.count == 2)
            #expect(notes[0].notations?.ornaments.count == 2)
            #expect(notes[0].notations?.tuplets.first?.actual?.dots == 1)
            #expect(notes[0].lyrics.first?.text == "la & <la>")
            #expect(notes[1].grace?.hasSlash == true)
            #expect(notes[2].isMeasureRest)
            #expect(notes[3].unpitched?.displayOctave == 5)
            #expect(measure.contents.compactMap { $0.as(.direction) }.first?.contents.count == 12)
        }
    }

    @Test func allDirectionTypeChildrenAreRead() throws {
        let xml = """
        <score-partwise><part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list>
        <part id="P1"><measure number="1"><direction><direction-type>
        <words>dolce</words><words>cantabile</words><segno/><coda/>
        </direction-type></direction></measure></part></score-partwise>
        """
        let score = try Score(data: Data(xml.utf8))
        #expect(score.parts[0].measures[0].contents[0].as(.direction)?.contents.count == 4)
    }

    @Test func overwritesDestinationAndUsesExplicitFormat() throws {
        try withDestination { destination in
            try generatedScore().write(to: destination)
            try generatedScore(title: "Replacement").write(to: destination, format: .musicxml)
            let data = try Data(contentsOf: destination.url)
            #expect(!data.starts(with: [0x50, 0x4B]))
            #expect(try AEXMLDocument(xml: data).root["work"]["work-title"].value == "Replacement")
        }
    }

    @Test func writePropagatesFileErrors() throws {
        try withDestination { destination in
            let missingParent = FinderItem(at: destination.url.appendingPathComponent("missing/score.mxl").path)
            #expect(throws: (any Error).self) { try generatedScore().write(to: missingParent) }
        }
    }

    @Test func optionalMetadataAndDefaultsAreOmitted() throws {
        let score = Score(partList: .init(scores: [.init(id: "P1", name: "Piano")]), parts: [.init(id: "P1", measures: [.init(number: "1", contents: [.note(.init(id: 0, duration: 4, type: .whole))])])])
        let root = try exportedXML(score).root
        #expect(root.children.map(\.name) == ["part-list", "part"])
        #expect(root["part"]["measure"]["note"]["rest"].error == nil)
    }
}

#if os(macOS)
extension WriterTests {
    /// Opt-in schema verification against a local copy of the official MusicXML 4.0 XSD.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["MUSICXML_SCHEMA_PATH"] != nil))
    func conformsToMusicXMLSchema() throws {
        let schema = try #require(ProcessInfo.processInfo.environment["MUSICXML_SCHEMA_PATH"])
        try withDestination { destination in
            try generatedScore().write(to: destination, format: .musicxml)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xmllint")
            process.arguments = ["--nonet", "--noout", "--schema", schema, destination.url.path]
            let diagnostics = Pipe()
            process.standardError = diagnostics
            try process.run()
            let output = diagnostics.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            #expect(process.terminationStatus == 0, "\(String(decoding: output, as: UTF8.self))")
        }
    }
}
#endif
