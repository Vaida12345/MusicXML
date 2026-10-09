import AEXML

extension MusicXMLDocument.Note {
    public struct Unpitched {
        public let displayStep: Pitch.Step?
        public let displayOctave: Int?

        public init(displayStep: Pitch.Step? = nil, displayOctave: Int? = nil) {
            self.displayStep = displayStep
            self.displayOctave = displayOctave
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.displayStep = try element.withOptionalChild(named: "display-step", AEXMLElement.asEnumContainer)
            self.displayOctave = try element.withOptionalChild(named: "display-octave", AEXMLElement.asIntContainer)
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "unpitched")
            element.addEnum("display-step", displayStep)
            element.addValue("display-octave", displayOctave)
            return element
        }
    }

    public struct Lyric {
        public let number: String?
        public let name: String?
        public let placement: MusicXMLDocument.Placement?
        public let syllabic: Syllabic?
        public let text: String?
        public let extend: MusicXMLDocument.Measure.StartStopContinue?

        public enum Syllabic: String, CaseIterable { case single, begin, end, middle }

        public init(text: String? = nil, syllabic: Syllabic? = nil, extend: MusicXMLDocument.Measure.StartStopContinue? = nil, number: String? = nil, name: String? = nil, placement: MusicXMLDocument.Placement? = nil) {
            self.text = text
            self.syllabic = syllabic
            self.extend = extend
            self.number = number
            self.name = name
            self.placement = placement
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.number = element.attributes["number"]
            self.name = element.attributes["name"]
            self.placement = try element.optionalEnumAttribute("placement")
            self.syllabic = try element.withOptionalChild(named: "syllabic", AEXMLElement.asEnumContainer)
            self.text = try element.withOptionalChild(named: "text", AEXMLElement.asTextContainer)
            self.extend = try element.withOptionalChild(named: "extend") { (child) throws(ParseError) in
                try child.optionalEnumAttribute("type") ?? .start
            }
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "lyric")
            element.setAttribute("number", number)
            element.setAttribute("name", name)
            element.setEnumAttribute("placement", placement)
            element.addEnum("syllabic", syllabic)
            element.addValue("text", text)
            if let extend { element.addChild(name: "extend", attributes: ["type": extend.rawValue]) }
            return element
        }
    }
}
