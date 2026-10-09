import AEXML

extension MusicXMLDocument.Measure {
    /// Local layout overrides and explicit page/system breaks.
    public struct Print {
        public let newSystem: Bool?
        public let newPage: Bool?
        public let pageNumber: String?
        public let blankPages: Int?
        public let pageLayout: MusicXMLDocument.Layout.PageLayout?
        public let systemLayout: MusicXMLDocument.Layout.SystemLayout?
        public let staffLayouts: [MusicXMLDocument.Layout.StaffLayout]
        public let measureDistance: Double?
        public let measureNumbering: MeasureNumbering?

        public enum MeasureNumbering: String, CaseIterable { case none, measure, system }

        public init(newSystem: Bool? = nil, newPage: Bool? = nil, pageNumber: String? = nil, blankPages: Int? = nil, pageLayout: MusicXMLDocument.Layout.PageLayout? = nil, systemLayout: MusicXMLDocument.Layout.SystemLayout? = nil, staffLayouts: [MusicXMLDocument.Layout.StaffLayout] = [], measureDistance: Double? = nil, measureNumbering: MeasureNumbering? = nil) {
            self.newSystem = newSystem
            self.newPage = newPage
            self.pageNumber = pageNumber
            self.blankPages = blankPages
            self.pageLayout = pageLayout
            self.systemLayout = systemLayout
            self.staffLayouts = staffLayouts
            self.measureDistance = measureDistance
            self.measureNumbering = measureNumbering
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.newSystem = try element.optionalYesNoAttribute("new-system")
            self.newPage = try element.optionalYesNoAttribute("new-page")
            self.pageNumber = element.attributes["page-number"]
            self.blankPages = try element.optionalAttribute("blank-page")
            self.pageLayout = try element.withOptionalChild(named: "page-layout", MusicXMLDocument.Layout.PageLayout.init)
            self.systemLayout = try element.withOptionalChild(named: "system-layout", MusicXMLDocument.Layout.SystemLayout.init)
            self.staffLayouts = try element.mapChildren(named: "staff-layout", MusicXMLDocument.Layout.StaffLayout.init)
            self.measureDistance = try element.withOptionalChild(named: "measure-layout") { (layout) throws(ParseError) in
                try layout.withOptionalChild(named: "measure-distance", AEXMLElement.asDoubleContainer)
            }
            self.measureNumbering = try element.withOptionalChild(named: "measure-numbering", AEXMLElement.asEnumContainer)
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "print")
            element.setYesNoAttribute("new-system", newSystem)
            element.setYesNoAttribute("new-page", newPage)
            element.setAttribute("page-number", pageNumber)
            element.setAttribute("blank-page", blankPages)
            if let pageLayout { element.addChild(pageLayout.xmlElement) }
            if let systemLayout { element.addChild(systemLayout.xmlElement) }
            for staff in staffLayouts { element.addChild(staff.xmlElement) }
            if let measureDistance { element.addChild(name: "measure-layout").addValue("measure-distance", measureDistance) }
            element.addEnum("measure-numbering", measureNumbering)
            return element
        }
    }
}
