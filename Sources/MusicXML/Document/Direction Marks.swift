import AEXML

extension MusicXMLDocument.Measure.Direction {
    public struct Pedal {
        public let type: Kind
        public let number: Int?
        public let line: Bool?
        public let sign: Bool?
        public let abbreviated: Bool?

        public enum Kind: String, CaseIterable { case start, stop, sostenuto, change, `continue`, resume, discontinue }

        public init(type: Kind, number: Int? = nil, line: Bool? = nil, sign: Bool? = nil, abbreviated: Bool? = nil) {
            self.type = type
            self.number = number
            self.line = line
            self.sign = sign
            self.abbreviated = abbreviated
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.type = try element.attribute(named: "type")
            self.number = try element.optionalAttribute("number")
            self.line = try element.optionalYesNoAttribute("line")
            self.sign = try element.optionalYesNoAttribute("sign")
            self.abbreviated = try element.optionalYesNoAttribute("abbreviated")
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "pedal", attributes: ["type": type.rawValue])
            element.setAttribute("number", number)
            element.setYesNoAttribute("line", line)
            element.setYesNoAttribute("sign", sign)
            element.setYesNoAttribute("abbreviated", abbreviated)
            return element
        }
    }

    public struct Bracket {
        public let type: MusicXMLDocument.Measure.StartStopContinue
        public let number: Int?
        public let lineEnd: LineEnd
        public let lineType: MusicXMLDocument.LineType?
        public let endLength: Double?

        public enum LineEnd: String, CaseIterable { case up, down, both, arrow, none }

        public init(type: MusicXMLDocument.Measure.StartStopContinue, lineEnd: LineEnd, number: Int? = nil, lineType: MusicXMLDocument.LineType? = nil, endLength: Double? = nil) {
            self.type = type
            self.lineEnd = lineEnd
            self.number = number
            self.lineType = lineType
            self.endLength = endLength
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.type = try element.attribute(named: "type")
            self.lineEnd = try element.attribute(named: "line-end")
            self.number = try element.optionalAttribute("number")
            self.lineType = try element.optionalEnumAttribute("line-type")
            self.endLength = try element.optionalAttribute("end-length")
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "bracket", attributes: ["type": type.rawValue, "line-end": lineEnd.rawValue])
            element.setAttribute("number", number)
            element.setEnumAttribute("line-type", lineType)
            element.setAttribute("end-length", endLength)
            return element
        }
    }
}
