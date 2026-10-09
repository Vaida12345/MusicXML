import AEXML
import DetailedDescription

extension MusicXMLDocument.Note {
    public struct Notations: DetailedStringConvertible {
        public let arpeggiations: [Arpeggiate]
        public let glissandos: [Glissando]
        public let slurs: [Slur]
        public let articulations: [Articulation]
        public let ornaments: [Ornament]
        public let tuplets: [Tuplet]

        /// Convenience access to the first mark, matching the original reading API.
        public var arpeggiate: Arpeggiate? { arpeggiations.first }
        public var glissando: Glissando? { glissandos.first }

        public init(arpeggiate: Arpeggiate? = nil, glissando: Glissando? = nil, arpeggiations: [Arpeggiate] = [], glissandos: [Glissando] = [], slurs: [Slur] = [], articulations: [Articulation] = [], ornaments: [Ornament] = [], tuplets: [Tuplet] = []) {
            self.arpeggiations = (arpeggiate.map { [$0] } ?? []) + arpeggiations
            self.glissandos = (glissando.map { [$0] } ?? []) + glissandos
            self.slurs = slurs
            self.articulations = articulations
            self.ornaments = ornaments
            self.tuplets = tuplets
        }

        init(element: AEXMLElement) throws(ParseError) {
            self.arpeggiations = try element.mapChildren(named: "arpeggiate", Arpeggiate.init)
            self.glissandos = try element.mapChildren(named: "glissando", Glissando.init)
            self.slurs = try element.mapChildren(named: "slur", Slur.init)
            self.tuplets = try element.mapChildren(named: "tuplet", Tuplet.init)
            var articulations: [Articulation] = []
            var ornaments: [Ornament] = []
            for container in element.children {
                if container.name == "articulations" {
                    for child in container.children where Articulation.Kind(rawValue: child.name) != nil {
                        articulations.append(try Articulation(element: child))
                    }
                } else if container.name == "ornaments" {
                    for child in container.children where Ornament.Kind(rawValue: child.name) != nil {
                        ornaments.append(try Ornament(element: child))
                    }
                }
            }
            self.articulations = articulations
            self.ornaments = ornaments
        }

        var xmlElement: AEXMLElement {
            let element = AEXMLElement(name: "notations")
            for slur in slurs { element.addChild(slur.xmlElement) }
            for tuplet in tuplets { element.addChild(tuplet.xmlElement) }
            for glissando in glissandos { element.addChild(glissando.xmlElement) }
            if !ornaments.isEmpty {
                let container = element.addChild(name: "ornaments")
                for ornament in ornaments { container.addChild(ornament.xmlElement) }
            }
            if !articulations.isEmpty {
                let container = element.addChild(name: "articulations")
                for articulation in articulations { container.addChild(articulation.xmlElement) }
            }
            for arpeggiation in arpeggiations { element.addChild(arpeggiation.xmlElement) }
            return element
        }

        public func detailedDescription(using descriptor: DetailedDescription.Descriptor<Self>) -> any DescriptionBlockProtocol {
            descriptor.container {
                descriptor.value(for: \.arpeggiations)
                descriptor.value(for: \.glissandos)
                descriptor.value(for: \.slurs)
                descriptor.value(for: \.articulations)
                descriptor.value(for: \.ornaments)
                descriptor.value(for: \.tuplets)
            }.hideEmptySequence()
        }

        public struct Arpeggiate {
            public let number: Int?

            public init(number: Int? = nil) { self.number = number }

            init(element: AEXMLElement) throws(ParseError) {
                self.number = try element.optionalAttribute("number")
            }

            var xmlElement: AEXMLElement {
                let element = AEXMLElement(name: "arpeggiate")
                element.setAttribute("number", number)
                return element
            }
        }

        public struct Glissando {
            public let type: MusicXMLDocument.Measure.StartStop
            public let number: Int?

            public init(type: MusicXMLDocument.Measure.StartStop, number: Int? = nil) {
                self.type = type
                self.number = number
            }

            init(element: AEXMLElement) throws(ParseError) {
                self.type = try element.attribute(named: "type")
                self.number = try element.optionalAttribute("number")
            }

            var xmlElement: AEXMLElement {
                let element = AEXMLElement(name: "glissando", attributes: ["type": type.rawValue])
                element.setAttribute("number", number)
                return element
            }
        }

        public struct Slur {
            public let type: MusicXMLDocument.Measure.StartStopContinue
            public let number: Int?
            public let placement: MusicXMLDocument.Placement?
            public let lineType: MusicXMLDocument.LineType?

            public init(type: MusicXMLDocument.Measure.StartStopContinue, number: Int? = nil, placement: MusicXMLDocument.Placement? = nil, lineType: MusicXMLDocument.LineType? = nil) {
                self.type = type
                self.number = number
                self.placement = placement
                self.lineType = lineType
            }

            init(element: AEXMLElement) throws(ParseError) {
                self.type = try element.attribute(named: "type")
                self.number = try element.optionalAttribute("number")
                self.placement = try element.optionalEnumAttribute("placement")
                self.lineType = try element.optionalEnumAttribute("line-type")
            }

            var xmlElement: AEXMLElement {
                let element = AEXMLElement(name: "slur", attributes: ["type": type.rawValue])
                element.setAttribute("number", number)
                element.setEnumAttribute("placement", placement)
                element.setEnumAttribute("line-type", lineType)
                return element
            }
        }

        public struct Articulation {
            public let kind: Kind
            public let placement: MusicXMLDocument.Placement?
            /// Text for breath marks, caesuras, and other-articulation.
            public let text: String?

            public enum Kind: String, CaseIterable {
                case accent, staccato, tenuto, staccatissimo, spiccato, scoop, plop, doit, falloff, stress, unstress
                case strongAccent = "strong-accent"
                case detachedLegato = "detached-legato"
                case breathMark = "breath-mark"
                case caesura
                case softAccent = "soft-accent"
                case other = "other-articulation"
            }

            public init(_ kind: Kind, placement: MusicXMLDocument.Placement? = nil, text: String? = nil) {
                self.kind = kind
                self.placement = placement
                self.text = text
            }

            init(element: AEXMLElement) throws(ParseError) {
                guard let kind = Kind(rawValue: element.name) else { throw .invalidValue(actual: element.name, acceptableValues: Kind.allCases.map(\.rawValue)) }
                self.kind = kind
                self.placement = try element.optionalEnumAttribute("placement")
                self.text = element.value
            }

            var xmlElement: AEXMLElement {
                let element = AEXMLElement(name: kind.rawValue, value: text)
                element.setEnumAttribute("placement", placement)
                return element
            }
        }

        public struct Ornament {
            public let kind: Kind
            public let placement: MusicXMLDocument.Placement?
            public let number: Int?
            public let type: MusicXMLDocument.Measure.StartStopContinue?
            public let tremoloType: TremoloType?
            /// Tremolo strokes, or text for other-ornament / accidental-mark.
            public let value: String?

            public enum Kind: String, CaseIterable {
                case trillMark = "trill-mark"
                case turn, delayedTurn = "delayed-turn", invertedTurn = "inverted-turn", delayedInvertedTurn = "delayed-inverted-turn"
                case verticalTurn = "vertical-turn", invertedVerticalTurn = "inverted-vertical-turn"
                case shake, wavyLine = "wavy-line", mordent, invertedMordent = "inverted-mordent", schleifer, tremolo
                case haydn, accidentalMark = "accidental-mark", other = "other-ornament"
            }
            public enum TremoloType: String, CaseIterable { case single, start, stop, unmeasured }

            public init(_ kind: Kind, placement: MusicXMLDocument.Placement? = nil, number: Int? = nil, type: MusicXMLDocument.Measure.StartStopContinue? = nil, tremoloType: TremoloType? = nil, value: String? = nil) {
                self.kind = kind
                self.placement = placement
                self.number = number
                self.type = type
                self.tremoloType = tremoloType
                self.value = value
            }

            init(element: AEXMLElement) throws(ParseError) {
                guard let kind = Kind(rawValue: element.name) else { throw .invalidValue(actual: element.name, acceptableValues: Kind.allCases.map(\.rawValue)) }
                self.kind = kind
                self.placement = try element.optionalEnumAttribute("placement")
                self.number = try element.optionalAttribute("number")
                self.type = kind == .wavyLine ? try element.optionalEnumAttribute("type") : nil
                self.tremoloType = kind == .tremolo ? try element.optionalEnumAttribute("type") : nil
                self.value = element.value
            }

            var xmlElement: AEXMLElement {
                let element = AEXMLElement(name: kind.rawValue, value: value)
                element.setEnumAttribute("placement", placement)
                element.setAttribute("number", number)
                if kind == .wavyLine { element.setEnumAttribute("type", type) }
                if kind == .tremolo { element.setEnumAttribute("type", tremoloType) }
                return element
            }
        }

        public struct Tuplet {
            public let type: MusicXMLDocument.Measure.StartStop
            public let number: Int?
            public let bracket: Bool?
            public let placement: MusicXMLDocument.Placement?
            public let showNumber: Display?
            public let showType: Display?
            public let actual: Portion?
            public let normal: Portion?

            public enum Display: String, CaseIterable { case actual, both, none }

            public init(type: MusicXMLDocument.Measure.StartStop, number: Int? = nil, bracket: Bool? = nil, placement: MusicXMLDocument.Placement? = nil, showNumber: Display? = nil, showType: Display? = nil, actual: Portion? = nil, normal: Portion? = nil) {
                self.type = type
                self.number = number
                self.bracket = bracket
                self.placement = placement
                self.showNumber = showNumber
                self.showType = showType
                self.actual = actual
                self.normal = normal
            }

            public struct Portion {
                public let number: Int?
                public let type: MusicXMLDocument.Note.NoteType?
                public let dots: Int

                public init(number: Int? = nil, type: MusicXMLDocument.Note.NoteType? = nil, dots: Int = 0) {
                    self.number = number
                    self.type = type
                    self.dots = dots
                }

                init(element: AEXMLElement) throws(ParseError) {
                    self.number = try element.withOptionalChild(named: "tuplet-number", AEXMLElement.asIntContainer)
                    self.type = try element.withOptionalChild(named: "tuplet-type", AEXMLElement.asEnumContainer)
                    self.dots = element.children.count(where: { $0.name == "tuplet-dot" })
                }

                func xmlElement(named name: String) -> AEXMLElement {
                    let element = AEXMLElement(name: name)
                    element.addValue("tuplet-number", number)
                    element.addEnum("tuplet-type", type)
                    element.addRepeated("tuplet-dot", count: dots)
                    return element
                }
            }

            init(element: AEXMLElement) throws(ParseError) {
                self.type = try element.attribute(named: "type")
                self.number = try element.optionalAttribute("number")
                self.bracket = try element.optionalYesNoAttribute("bracket")
                self.placement = try element.optionalEnumAttribute("placement")
                self.showNumber = try element.optionalEnumAttribute("show-number")
                self.showType = try element.optionalEnumAttribute("show-type")
                self.actual = try element.withOptionalChild(named: "tuplet-actual", Portion.init)
                self.normal = try element.withOptionalChild(named: "tuplet-normal", Portion.init)
            }

            var xmlElement: AEXMLElement {
                let element = AEXMLElement(name: "tuplet", attributes: ["type": type.rawValue])
                element.setAttribute("number", number)
                element.setYesNoAttribute("bracket", bracket)
                element.setEnumAttribute("placement", placement)
                element.setEnumAttribute("show-number", showNumber)
                element.setEnumAttribute("show-type", showType)
                if let actual { element.addChild(actual.xmlElement(named: "tuplet-actual")) }
                if let normal { element.addChild(normal.xmlElement(named: "tuplet-normal")) }
                return element
            }
        }
    }
}
