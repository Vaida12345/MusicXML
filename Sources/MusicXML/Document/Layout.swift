import AEXML

extension MusicXMLDocument {
    /// Score-wide defaults. All dimensions except scaling's millimeters are in tenths of a staff space.
    public struct Layout {
        public let pageWidth: Double?
        public let pageHeight: Double?
        public let pageMargins: [PageMargins]
        public let scaling: Scaling?
        public let system: SystemLayout?
        public let staves: [StaffLayout]
        public let appearance: Appearance?
        public let musicFont: Font?
        public let wordFont: Font?
        public let lyricFont: Font?

        public init(pageWidth: Double? = nil, pageHeight: Double? = nil, pageMargins: [PageMargins] = [], scaling: Scaling? = nil, system: SystemLayout? = nil, staves: [StaffLayout] = [], appearance: Appearance? = nil, musicFont: Font? = nil, wordFont: Font? = nil, lyricFont: Font? = nil) {
            self.pageWidth = pageWidth
            self.pageHeight = pageHeight
            self.pageMargins = pageMargins
            self.scaling = scaling
            self.system = system
            self.staves = staves
            self.appearance = appearance
            self.musicFont = musicFont
            self.wordFont = wordFont
            self.lyricFont = lyricFont
        }

        init(root: AEXMLElement) throws(ParseError) {
            guard let defaults = root.children.first(where: { $0.name == "defaults" }) else {
                self.init()
                return
            }
            let page = try defaults.withOptionalChild(named: "page-layout", PageLayout.init)
            self.init(
                pageWidth: page?.width, pageHeight: page?.height, pageMargins: page?.margins ?? [],
                scaling: try defaults.withOptionalChild(named: "scaling", Scaling.init),
                system: try defaults.withOptionalChild(named: "system-layout", SystemLayout.init),
                staves: try defaults.mapChildren(named: "staff-layout", StaffLayout.init),
                appearance: try defaults.withOptionalChild(named: "appearance", Appearance.init),
                musicFont: try defaults.withOptionalChild(named: "music-font", Font.init),
                wordFont: try defaults.withOptionalChild(named: "word-font", Font.init),
                lyricFont: try defaults.withOptionalChild(named: "lyric-font", Font.init)
            )
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "defaults")
            if let scaling { element.addChild(scaling.xmlElement) }
            if pageWidth != nil || pageHeight != nil || !pageMargins.isEmpty {
                element.addChild(PageLayout(width: pageWidth, height: pageHeight, margins: pageMargins).xmlElement)
            }
            if let system { element.addChild(system.xmlElement) }
            for staff in staves { element.addChild(staff.xmlElement) }
            if let appearance { element.addChild(appearance.xmlElement) }
            if let musicFont { element.addChild(musicFont.xmlElement(named: "music-font")) }
            if let wordFont { element.addChild(wordFont.xmlElement(named: "word-font")) }
            if let lyricFont { element.addChild(lyricFont.xmlElement(named: "lyric-font")) }
            return element
        }
    }

    public struct Font {
        public let family: String?
        public let size: Double?
        public let style: Style?
        public let weight: Weight?

        public init(family: String? = nil, size: Double? = nil, style: Style? = nil, weight: Weight? = nil) {
            self.family = family
            self.size = size
            self.style = style
            self.weight = weight
        }

        public enum Style: String, CaseIterable { case normal, italic }
        public enum Weight: String, CaseIterable { case normal, bold }

        init(element: AEXMLElement) throws(ParseError) {
            self.family = element.attributes["font-family"]
            self.size = try element.optionalAttribute("font-size")
            self.style = try element.optionalEnumAttribute("font-style")
            self.weight = try element.optionalEnumAttribute("font-weight")
        }

        func apply(to element: AEXMLElement) {
            element.setAttribute("font-family", family)
            element.setAttribute("font-size", size)
            element.setEnumAttribute("font-style", style)
            element.setEnumAttribute("font-weight", weight)
        }

        func xmlElement(named name: String) -> AEXMLElement {
            let element = AEXMLElement(name: name)
            apply(to: element)
            return element
        }
    }
}

extension MusicXMLDocument.Layout {
    public struct Appearance {
        public let lineWidths: [LineWidth]
        public let noteSizes: [NoteSize]

        public init(lineWidths: [LineWidth] = [], noteSizes: [NoteSize] = []) {
            self.lineWidths = lineWidths
            self.noteSizes = noteSizes
        }

        public struct LineWidth {
            /// MusicXML line category, such as "staff", "stem", or "beam".
            public let type: String
            public let width: Double

            public init(type: String, width: Double) {
                self.type = type
                self.width = width
            }

            init(element: AEXMLElement) throws(ParseError) {
                self.type = try element.attribute(named: "type")
                self.width = try element.asDoubleContainer()
            }
        }

        public struct NoteSize {
            public let type: Kind
            /// Percentage of the normal note size.
            public let size: Double

            public enum Kind: String, CaseIterable { case cue, grace; case graceCue = "grace-cue"; case large }

            public init(type: Kind, size: Double) {
                self.type = type
                self.size = size
            }

            init(element: AEXMLElement) throws(ParseError) {
                self.type = try element.attribute(named: "type")
                self.size = try element.asDoubleContainer()
            }
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.lineWidths = try element.mapChildren(named: "line-width", LineWidth.init)
            self.noteSizes = try element.mapChildren(named: "note-size", NoteSize.init)
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "appearance")
            for line in lineWidths {
                element.addChild(name: "line-width", value: String(line.width), attributes: ["type": line.type])
            }
            for note in noteSizes {
                element.addChild(name: "note-size", value: String(note.size), attributes: ["type": note.type.rawValue])
            }
            return element
        }
    }
}
