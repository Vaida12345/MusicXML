import AEXML

extension MusicXMLDocument.Note {
    /// Coordinates for the end of a stem, in tenths of a staff space.
    /// The exporter calculates these from its stem-length and beam preferences.
    /// Supply a stem direction alongside geometry when constructing a note.
    public struct StemGeometry: Equatable, Sendable {
        /// Horizontal endpoint relative to the left side of the note.
        public let defaultX: Double?
        /// Vertical endpoint relative to the top staff line.
        public let defaultY: Double?
        /// Horizontal adjustment relative to the default endpoint.
        public let relativeX: Double?
        /// Stem-length adjustment relative to the default endpoint.
        public let relativeY: Double?

        public init(defaultX: Double? = nil, defaultY: Double? = nil, relativeX: Double? = nil, relativeY: Double? = nil) {
            self.defaultX = defaultX
            self.defaultY = defaultY
            self.relativeX = relativeX
            self.relativeY = relativeY
        }

        init?(element: AEXMLElement) throws(ParseError) {
            guard ["default-x", "default-y", "relative-x", "relative-y"].contains(where: { element.attributes[$0] != nil }) else { return nil }
            self.defaultX = try element.optionalAttribute("default-x")
            self.defaultY = try element.optionalAttribute("default-y")
            self.relativeX = try element.optionalAttribute("relative-x")
            self.relativeY = try element.optionalAttribute("relative-y")
        }

        func apply(to element: AEXMLElement) {
            element.setAttribute("default-x", defaultX)
            element.setAttribute("default-y", defaultY)
            element.setAttribute("relative-x", relativeX)
            element.setAttribute("relative-y", relativeY)
        }
    }
}
