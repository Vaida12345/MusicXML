import AEXML

extension MusicXMLDocument.Note {
    /// Text inside a staff notehead, such as "1", "C", or "Do".
    /// Pitch, clef, duration, and note type retain their ordinary musical meanings.
    public struct NoteheadText {
        /// Ordered display-text segments, each with its own optional formatting.
        public let displayTexts: [MusicXMLDocument.FormattedText]

        public init(displayTexts: [MusicXMLDocument.FormattedText]) {
            self.displayTexts = displayTexts
        }

        /// Constructs a single display-text segment.
        public init(_ text: String, font: MusicXMLDocument.Font? = nil) {
            self.init(displayTexts: [.init(text, font: font)])
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.displayTexts = try element.mapChildren(named: "display-text", MusicXMLDocument.FormattedText.init)
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "notehead-text")
            for text in displayTexts { element.addChild(text.xmlElement(named: "display-text")) }
            return element
        }
    }
}
