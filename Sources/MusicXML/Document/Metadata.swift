import AEXML

extension MusicXMLDocument {
    /// Text used by score credits, textual directions, and notehead text.
    public struct FormattedText {
        public let text: String
        public let font: Font?
        public let defaultX: Double?
        public let defaultY: Double?
        public let justify: Justify?
        public let verticalAlignment: VerticalAlignment?

        public enum Justify: String, CaseIterable { case left, center, right }
        public enum VerticalAlignment: String, CaseIterable { case top, middle, bottom, baseline }

        public init(_ text: String, font: Font? = nil, defaultX: Double? = nil, defaultY: Double? = nil, justify: Justify? = nil, verticalAlignment: VerticalAlignment? = nil) {
            self.text = text
            self.font = font
            self.defaultX = defaultX
            self.defaultY = defaultY
            self.justify = justify
            self.verticalAlignment = verticalAlignment
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.text = try element.asTextContainer()
            self.font = element.attributes.keys.contains(where: { $0.hasPrefix("font-") }) ? try Font(element: element) : nil
            self.defaultX = try element.optionalAttribute("default-x")
            self.defaultY = try element.optionalAttribute("default-y")
            self.justify = try element.optionalEnumAttribute("justify")
            self.verticalAlignment = try element.optionalEnumAttribute("valign")
        }

        func xmlElement(named name: String) -> AEXMLElement {
            let element = AEXMLElement(name: name, value: text)
            font?.apply(to: element)
            element.setAttribute("default-x", defaultX)
            element.setAttribute("default-y", defaultY)
            element.setEnumAttribute("justify", justify)
            element.setEnumAttribute("valign", verticalAlignment)
            return element
        }
    }

    /// Page text, independent of title/composer metadata. Page numbers start at 1.
    public struct Credit {
        public let page: Int?
        /// MusicXML credit categories, such as "title", "composer", or "rights".
        public let types: [String]
        public let words: [FormattedText]

        public init(page: Int? = nil, types: [String] = [], words: [FormattedText]) {
            self.page = page
            self.types = types
            self.words = words
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.page = try element.optionalAttribute("page")
            self.types = try element.mapChildren(named: "credit-type") { (child) throws(ParseError) in
                try child.asTextContainer()
            }
            self.words = try element.mapChildren(named: "credit-words", FormattedText.init)
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "credit")
            element.setAttribute("page", page)
            for type in types { element.addValue("credit-type", type) }
            for word in words { element.addChild(word.xmlElement(named: "credit-words")) }
            return element
        }
    }
}
