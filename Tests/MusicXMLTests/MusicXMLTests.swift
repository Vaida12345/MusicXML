import Testing
import Foundation
@testable import MusicXML

let text = """
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE score-partwise PUBLIC
"-//Recordare//DTD MusicXML 4.0 Partwise//EN"
"http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="4.0">
<part-list>
<score-part id="P1">
  <part-name>Music</part-name>
</score-part>
</part-list>
<part id="P1">
<measure number="1">
  <attributes>
    <divisions>1</divisions>
    <key>
      <fifths>0</fifths>
    </key>
    <time>
      <beats>4</beats>
      <beat-type>4</beat-type>
    </time>
    <clef>
      <sign>G</sign>
      <line>2</line>
    </clef>
  </attributes>
  <note>
    <pitch>
      <step>C</step>
      <octave>4</octave>
    </pitch>
    <duration>4</duration>
    <type>whole</type>
  </note>
</measure>
</part>
</score-partwise>
"""

@Test func example() async throws {
    let data = text.data(using: .utf8)!
    let musicXML = try MusicXMLDocument(data: data)
    
    #expect(musicXML.version == "4.0")
    
    #expect(musicXML.partList.count == 1)
    let partList = musicXML.partList.first!
    #expect(partList.id == "P1")
    #expect(partList.name == "Music")
    
    #expect(musicXML.parts.count == 1)
    let part = musicXML.parts.first!
    #expect(part.id == "P1")
    #expect(part.measures.count == 1)
    let measure = part.measures.first!
    #expect(measure.number == "1")
    
    let attributes = measure.attributes!
    #expect(attributes.divisions == 1)
    #expect(attributes.keySignature.fifths == 0)
    #expect(attributes.timeSignature.beats == 4)
    #expect(attributes.timeSignature.beatType == 4)
    #expect(attributes.clef.sign == .treble)
    #expect(attributes.clef.line == 2)
    
    #expect(measure.notes.count == 1)
    let note = measure.notes.first!
    #expect(note.pitch.step == .C)
    #expect(note.pitch.octave == 4)
    #expect(note.pitch.alteration == nil)
    #expect(note.duration == 4)
    #expect(note.type == .whole)
}

@Test func nightfall() async throws {
    let source = URL(filePath: "/Users/vaida/DataBase/Swift Package/Test Reference/MusicXML/Nightfall.musicxml")
    let data = try Data(contentsOf: source)
    let document = try MusicXMLDocument(data: data)
    print(document)
}


@Test func compressed() async throws {
    let source = URL(filePath: "/Users/vaida/DataBase/Swift Package/Test Reference/MusicXML/Nightfall.mxl")
    let data = try Data(contentsOf: source)
    let document = try MusicXMLDocument(data: data)
    print(document)
}
