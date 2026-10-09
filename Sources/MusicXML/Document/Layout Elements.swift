import AEXML

extension MusicXMLDocument.Layout {
    public struct Scaling {
        public let millimeters: Double
        public let tenths: Double

        public init(millimeters: Double, tenths: Double) {
            self.millimeters = millimeters
            self.tenths = tenths
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.millimeters = try element.withChild(named: "millimeters", AEXMLElement.asDoubleContainer)
            self.tenths = try element.withChild(named: "tenths", AEXMLElement.asDoubleContainer)
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "scaling")
            element.addValue("millimeters", millimeters)
            element.addValue("tenths", tenths)
            return element
        }
    }

    public struct PageLayout {
        public let width: Double?
        public let height: Double?
        public let margins: [PageMargins]

        public init(width: Double? = nil, height: Double? = nil, margins: [PageMargins] = []) {
            self.width = width
            self.height = height
            self.margins = margins
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.width = try element.withOptionalChild(named: "page-width", AEXMLElement.asDoubleContainer)
            self.height = try element.withOptionalChild(named: "page-height", AEXMLElement.asDoubleContainer)
            self.margins = try element.mapChildren(named: "page-margins", PageMargins.init)
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "page-layout")
            element.addValue("page-height", height)
            element.addValue("page-width", width)
            for value in margins { element.addChild(value.xmlElement) }
            return element
        }
    }

    public struct PageMargins {
        public let left: Double
        public let right: Double
        public let top: Double
        public let bottom: Double
        public let type: MarginType?

        public init(left: Double, right: Double, top: Double, bottom: Double, type: MarginType? = nil) {
            self.left = left
            self.right = right
            self.top = top
            self.bottom = bottom
            self.type = type
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.left = try element.withChild(named: "left-margin", AEXMLElement.asDoubleContainer)
            self.right = try element.withChild(named: "right-margin", AEXMLElement.asDoubleContainer)
            self.top = try element.withChild(named: "top-margin", AEXMLElement.asDoubleContainer)
            self.bottom = try element.withChild(named: "bottom-margin", AEXMLElement.asDoubleContainer)
            self.type = try element.optionalEnumAttribute("type")
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "page-margins")
            element.addValue("left-margin", left)
            element.addValue("right-margin", right)
            element.addValue("top-margin", top)
            element.addValue("bottom-margin", bottom)
            element.setEnumAttribute("type", type)
            return element
        }
    }

    public struct SystemLayout {
        public let margins: SystemMargins?
        public let distance: Double?
        public let topDistance: Double?

        public init(margins: SystemMargins? = nil, distance: Double? = nil, topDistance: Double? = nil) {
            self.margins = margins
            self.distance = distance
            self.topDistance = topDistance
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.margins = try element.withOptionalChild(named: "system-margins", SystemMargins.init)
            self.distance = try element.withOptionalChild(named: "system-distance", AEXMLElement.asDoubleContainer)
            self.topDistance = try element.withOptionalChild(named: "top-system-distance", AEXMLElement.asDoubleContainer)
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "system-layout")
            if let margins { element.addChild(margins.xmlElement) }
            element.addValue("system-distance", distance)
            element.addValue("top-system-distance", topDistance)
            return element
        }
    }

    public struct SystemMargins {
        public let left: Double
        public let right: Double

        public init(left: Double, right: Double) {
            self.left = left
            self.right = right
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.left = try element.withChild(named: "left-margin", AEXMLElement.asDoubleContainer)
            self.right = try element.withChild(named: "right-margin", AEXMLElement.asDoubleContainer)
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "system-margins")
            element.addValue("left-margin", left)
            element.addValue("right-margin", right)
            return element
        }
    }

    public struct StaffLayout {
        public let number: Int?
        public let distance: Double?

        public init(number: Int? = nil, distance: Double? = nil) {
            self.number = number
            self.distance = distance
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.number = try element.optionalAttribute("number")
            self.distance = try element.withOptionalChild(named: "staff-distance", AEXMLElement.asDoubleContainer)
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "staff-layout")
            element.setAttribute("number", number)
            element.addValue("staff-distance", distance)
            return element
        }
    }

    public enum MarginType: String, CaseIterable {
        case odd, even, both
    }
}
