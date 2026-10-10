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
                    lyrics: [.init(text: "la & <la>", syllabic: .begin, extend: .start, number: "1", placement: .below)],
                    stemGeometry: .init(defaultX: 12.5, defaultY: 35, relativeX: -1.5, relativeY: 7.25), midiVelocity: 100, noteheadText: .init("Do"))
    let measure = Measure(number: "1", attributes: .init(divisions: 4, keySignature: .init(value: .traditional(fifths: 1, mode: .major)),
                                                          timeSignature: .init(beats: 4, beatType: 4), staves: 2, clef: .init(sign: .treble, line: 2), clefs: [.init(sign: .bass, line: 4, number: 2)]), contents: [
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
                                                                        defaultX: 600, defaultY: 1500, justify: .center, verticalAlignment: .top)])],
                 encodingSoftware: ["Engraver & <Exporter>", "MusicXML Framework"])
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

private func exportedXML(_ score: Score, format: Score.ExportFormat = .musicXML) throws -> AEXMLDocument {
    try withDestination { destination in
        try score.write(to: destination, format: format)
        let data = try Data(contentsOf: destination.url)
        if format == .musicXML { return try AEXMLDocument(xml: data) }
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
            try generatedScore(title: "Replacement").write(to: destination, format: .musicXML)
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
            try generatedScore().write(to: destination, format: .musicXML)
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

extension WriterTests {
    @Test(arguments: Score.ExportFormat.allCases)
    func staffClefsStemGeometryAndVelocity(format: Score.ExportFormat) throws {
        let score = generatedScore()
        let original = try #require(score.parts[0].measures[0].attributes)
        #expect(original.clef?.sign == .treble)
        #expect(original.clefs.count == 2)
        let root = try exportedXML(score, format: format).root
        let measure = root["part"]["measure"]
        let clefs = measure["attributes"].children.filter { $0.name == "clef" }
        #expect(clefs.count == 2)
        #expect(clefs[0]["sign"].value == "G")
        #expect(clefs[0].attributes["number"] == nil)
        #expect(clefs[1]["sign"].value == "F")
        #expect(clefs[1].attributes["number"] == "2")
        let note = measure["note"]
        #expect(note.attributes["dynamics"].flatMap(Double.init) == Note.dynamics(forMIDIVelocity: 100))
        #expect(note["stem"].value == "up")
        #expect(note["stem"].attributes["default-x"] == "12.5")
        #expect(note["stem"].attributes["default-y"] == "35.0")
        #expect(note["stem"].attributes["relative-x"] == "-1.5")
        #expect(note["stem"].attributes["relative-y"] == "7.25")
        #expect(note.attributes["default-x"] == nil)
        #expect(measure["direction"]["sound"].attributes["dynamics"] == "60.0")
        try withDestination { destination in
            try score.write(to: destination, format: format)
            let decoded = try Score(data: Data(contentsOf: destination.url))
            let attributes = try #require(decoded.parts[0].measures[0].attributes)
            #expect(attributes.clefs.map(\.number) == [nil, 2])
            #expect(attributes.clefs.map(\.sign) == [.treble, .bass])
            #expect(attributes.clef?.sign == .treble)
            let decodedNote = try #require(decoded.parts[0].measures[0].contents.compactMap { $0.as(.note) }.first)
            #expect(decodedNote.stem == .up)
            #expect(decodedNote.stemGeometry == .init(defaultX: 12.5, defaultY: 35, relativeX: -1.5, relativeY: 7.25))
            #expect(decodedNote.midiVelocity == 100)
        }
    }

    @Test func parsesIndependentClefsAndNoteAttributes() throws {
        let xml = """
        <score-partwise><part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list>
        <part id="P1"><measure number="1"><attributes><staves>2</staves>
        <clef number="1"><sign>G</sign><line>2</line></clef>
        <clef number="2"><sign>F</sign><line>4</line></clef></attributes>
        <note dynamics="100"><pitch><step>C</step><octave>4</octave></pitch><duration>1</duration>
        <stem default-x="0" default-y="-35.5" relative-x="2" relative-y="-4">down</stem></note>
        <note><rest/><duration>1</duration><stem>up</stem></note>
        <note><rest/><duration>1</duration></note>
        </measure></part></score-partwise>
        """
        let score = try Score(data: Data(xml.utf8))
        let measure = score.parts[0].measures[0]
        #expect(measure.attributes?.clefs.map(\.number) == [1, 2])
        #expect(measure.attributes?.clef?.number == 1)
        let notes = measure.contents.compactMap { $0.as(.note) }
        #expect(notes[0].stem == .down)
        #expect(notes[0].stemGeometry == .init(defaultX: 0, defaultY: -35.5, relativeX: 2, relativeY: -4))
        #expect(notes[0].dynamics == 100)
        #expect(notes[0].midiVelocity == 90)
        #expect(notes[1].stem == .up)
        #expect(notes[1].stemGeometry == nil)
        #expect(notes[1].dynamics == nil)
        #expect(notes[1].midiVelocity == nil)
        #expect(notes[2].stem == nil)
        #expect(notes[2].stemGeometry == nil)
    }

    @Test func preservesSingleClefAndStemAPI() throws {
        let legacy = Measure.Attributes(clef: .init(sign: .treble, line: 2))
        #expect(legacy.clef?.sign == .treble)
        #expect(legacy.clef?.number == nil)
        #expect(legacy.clefs.count == 1)
        let score = Score(partList: .init(scores: [.init(id: "P1", name: "Piano")]), parts: [.init(id: "P1", measures: [
            .init(number: "1", attributes: legacy, contents: [.note(.init(id: 0, duration: 1, stem: .down))])
        ])])
        let measure = try exportedXML(score).root["part"]["measure"]
        #expect(measure["attributes"].children.filter { $0.name == "clef" }.count == 1)
        #expect(measure["attributes"]["clef"].attributes.isEmpty)
        #expect(measure["note"]["stem"].value == "down")
        #expect(measure["note"]["stem"].attributes.isEmpty)
        #expect(measure["note"].attributes["dynamics"] == nil)
        #expect(Measure.Attributes().clef == nil)
        #expect(Measure.Attributes().clefs.isEmpty)
        let separate = Measure.Attributes(clefs: [.init(sign: .bass, line: 4, number: 2)])
        #expect(separate.clef?.sign == .bass)
        #expect(separate.clefs.count == 1)
    }

    @Test func optionalStemCoordinatesAndDynamicsAreSerialized() throws {
        let score = Score(partList: .init(scores: [.init(id: "P1", name: "Piano")]), parts: [.init(id: "P1", measures: [
            .init(number: "1", contents: [.note(.init(id: 0, duration: 1, stem: .up, stemGeometry: .init(relativeY: 0), dynamics: 0))])
        ])])
        let note = try exportedXML(score).root["part"]["measure"]["note"]
        #expect(note.attributes["dynamics"] == "0.0")
        #expect(note["stem"].attributes == ["relative-y": "0.0"])
        #expect(Note(id: 0, dynamics: 75, midiVelocity: 90).dynamics == 75)
        #expect(Note(id: 0, midiVelocity: 90).dynamics == 100)
        #expect(Note(id: 0, midiVelocity: 0).midiVelocity == 0)
    }

    @Test func velocityConversionCoversEntireMIDIRange() {
        for velocity in 0...127 {
            let dynamics = Note.dynamics(forMIDIVelocity: velocity)
            #expect(dynamics == Double(velocity) * 100 / 90)
            #expect(Note.midiVelocity(forDynamics: dynamics) == velocity)
            #expect(Note(id: velocity, midiVelocity: velocity).midiVelocity == velocity)
        }
        #expect(Note.dynamics(forMIDIVelocity: 90) == 100)
        #expect(Note.dynamics(forMIDIVelocity: 127) > 100)
    }

    @Test func velocityConversionRoundsAndClamps() {
        #expect(Note.midiVelocity(forDynamics: 15) == 14) // 13.5 rounds up.
        #expect(Note.midiVelocity(forDynamics: 14.99) == 13)
        #expect(Note.midiVelocity(forDynamics: 100) == 90)
        #expect(Note.midiVelocity(forDynamics: -1) == 0)
        #expect(Note.midiVelocity(forDynamics: 200) == 127)
        #expect(Note.midiVelocity(forDynamics: .greatestFiniteMagnitude) == 127)
        #expect(Note.midiVelocity(forDynamics: .infinity) == 127)
        #expect(Note.midiVelocity(forDynamics: -.infinity) == 0)
        #expect(Note.midiVelocity(forDynamics: .nan) == 0)
    }
}

extension WriterTests {
    @Test(arguments: Score.ExportFormat.allCases)
    func encodingSoftwareCoexistsWithComposer(format: Score.ExportFormat) throws {
        let root = try exportedXML(generatedScore(), format: format).root
        let identifications = root.children.filter { $0.name == "identification" }
        #expect(identifications.count == 1)
        let identification = try #require(identifications.first)
        #expect(identification.children.map(\.name) == ["creator", "encoding"])
        #expect(identification["creator"].value == "A & B")
        #expect(identification["creator"].attributes["type"] == "composer")
        #expect(identification["encoding"].children.map(\.value) == ["Engraver & <Exporter>", "MusicXML Framework"])
        try withDestination { destination in
            try generatedScore().write(to: destination, format: format)
            let decoded = try Score(data: Data(contentsOf: destination.url))
            #expect(decoded.composer == "A & B")
            #expect(decoded.encodingSoftware == ["Engraver & <Exporter>", "MusicXML Framework"])
        }
    }

    @Test func softwareOnlyAndComposerOnlyMetadata() throws {
        let partList = Score.PartList(scores: [.init(id: "P1", name: "Piano")])
        let parts = [Score.Part(id: "P1", measures: [.init(number: "1", contents: [.note(.init(id: 0, duration: 1))])])]
        let softwareOnly = Score(partList: partList, parts: parts, encodingSoftware: ["Exporter"])
        let softwareIdentification = try exportedXML(softwareOnly).root["identification"]
        #expect(softwareIdentification.children.map(\.name) == ["encoding"])
        #expect(softwareIdentification["encoding"]["software"].value == "Exporter")
        let composerOnly = Score(partList: partList, parts: parts, composer: "Composer")
        #expect(try exportedXML(composerOnly).root["identification"].children.map(\.name) == ["creator"])
        #expect(composerOnly.encodingSoftware.isEmpty)
        let empty = Score(partList: partList, parts: parts)
        #expect(try exportedXML(empty).root.children.filter { $0.name == "identification" }.isEmpty)
    }

    @Test(arguments: ["1", "C", "Do", "Ré", "Si♭", "C & <D>"])
    func noteheadLabelsPreserveMusicalContent(label: String) throws {
        let note = Note(id: 0, pitch: .init(step: .D, alteration: -1, octave: 4), duration: 3,
                        type: .eighth, dot: 1, stem: .up, staff: 1, noteheadText: .init(label))
        let score = Score(partList: .init(scores: [.init(id: "P1", name: "Piano")]), parts: [.init(id: "P1", measures: [
            .init(number: "1", attributes: .init(divisions: 4, clef: .init(sign: .treble, line: 2)), contents: [.note(note)])
        ])])
        let measure = try exportedXML(score).root["part"]["measure"]
        let writtenNote = measure["note"]
        #expect(writtenNote["notehead-text"]["display-text"].value == label)
        #expect(writtenNote["pitch"]["step"].value == "D")
        #expect(writtenNote["pitch"]["alter"].double == -1)
        #expect(writtenNote["duration"].int == 3)
        #expect(writtenNote["type"].value == "eighth")
        #expect(writtenNote.children.filter { $0.name == "dot" }.count == 1)
        #expect(measure["attributes"]["clef"]["sign"].value == "G")
        #expect(!writtenNote.children.contains { $0.name == "lyric" || $0.name == "unpitched" || $0.name == "notehead" })
        #expect(writtenNote.children.map(\.name) == ["pitch", "duration", "type", "dot", "stem", "notehead-text", "staff"])
    }

    @Test(arguments: Score.ExportFormat.allCases)
    func importedSoftwareAndNoteheadTextSurviveReadWrite(format: Score.ExportFormat) throws {
        let xml = """
        <score-partwise version="4.0"><identification>
        <creator type="composer">Composer &amp; Co.</creator>
        <encoding><software>First &amp; Second</software><software>Exporter 2</software></encoding>
        </identification><part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list>
        <part id="P1"><measure number="1"><attributes><divisions>4</divisions>
        <clef number="1"><sign>G</sign><line>2</line></clef><clef number="2"><sign>F</sign><line>4</line></clef></attributes>
        <note><pitch><step>C</step><octave>4</octave></pitch><duration>2</duration><type>eighth</type>
        <stem>up</stem><notehead-text>
        <display-text font-family="Times New Roman" font-size="8" font-weight="bold">Ré</display-text>
        <display-text font-style="italic" default-x="1.5" default-y="-10" justify="center" valign="middle">♭</display-text>
        </notehead-text><staff>1</staff></note>
        <note><pitch><step>D</step><octave>4</octave></pitch><duration>2</duration><type>eighth</type></note>
        </measure></part></score-partwise>
        """
        let original = try Score(data: Data(xml.utf8))
        #expect(original.encodingSoftware == ["First & Second", "Exporter 2"])
        let originalNote = try #require(original.parts[0].measures[0].contents[0].as(.note))
        #expect(originalNote.noteheadText?.displayTexts.map(\.text) == ["Ré", "♭"])
        #expect(original.parts[0].measures[0].contents[1].as(.note)?.noteheadText == nil)
        try withDestination { destination in
            try original.write(to: destination, format: format)
            let decoded = try Score(data: Data(contentsOf: destination.url))
            #expect(decoded.composer == original.composer)
            #expect(decoded.encodingSoftware == original.encodingSoftware)
            let measure = decoded.parts[0].measures[0]
            #expect(measure.attributes?.clefs.map(\.number) == [1, 2])
            #expect(measure.attributes?.clefs.map(\.sign) == [.treble, .bass])
            let note = try #require(measure.contents[0].as(.note))
            #expect(note.pitch == originalNote.pitch)
            #expect(note.duration == originalNote.duration)
            #expect(note.type == originalNote.type)
            #expect(note.stem == originalNote.stem)
            #expect(note.staff == originalNote.staff)
            let texts = try #require(note.noteheadText?.displayTexts)
            #expect(texts.map(\.text) == ["Ré", "♭"])
            #expect(texts[0].font?.family == "Times New Roman")
            #expect(texts[0].font?.size == 8)
            #expect(texts[0].font?.weight == .bold)
            #expect(texts[1].font?.style == .italic)
            #expect(texts[1].defaultX == 1.5)
            #expect(texts[1].defaultY == -10)
            #expect(texts[1].justify == .center)
            #expect(texts[1].verticalAlignment == .middle)
            #expect(measure.contents[1].as(.note)?.noteheadText == nil)
        }
    }
}
