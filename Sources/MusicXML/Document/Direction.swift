//
//  Direction.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-25.
//

import Foundation
import AEXML
import DetailedDescription
import MacroCollection


extension MusicXMLDocument.Measure {

    public struct Direction {
        
        public let contents: [Content]
        public let sound: Sound?
        /// Staff values are numbers, with 1 referring to the top-most staff in a part.
        public let staff: Int?
        public let placement: MusicXMLDocument.Placement?
        public let voice: Int?
        /// Offset from the current musical position, in divisions.
        public let offset: Double?
        
        @accessingAssociatedValues
        public enum Content {
            case metronome(Metronome)
            case octaveShift(OctaveShift)
            /// Represents crescendo and diminuendo wedge symbols.
            case wedge(Wedge)
            case dynamics(Dynamics)
            case dashes(Dashes)
            case words(MusicXMLDocument.FormattedText)
            case rehearsal(MusicXMLDocument.FormattedText)
            case segno
            case coda
            case pedal(Pedal)
            case bracket(Bracket)
            case unknown(String)
        }

        init(element: AEXMLElement) throws(ParseError) {
            assert(element.name == "direction")
            
            var words: AEXMLElement?
            var contents: [Content] = []
            for container in element.children where container.name == "direction-type" {
                for child in container.children {
                    switch child.name {
                    case "metronome": contents.append(.metronome(try Metronome(element: child)))
                    case "octave-shift": contents.append(.octaveShift(try OctaveShift(element: child)))
                    case "wedge": contents.append(.wedge(try Wedge(element: child)))
                    case "dynamics": contents.append(.dynamics(try Dynamics(element: child)))
                    case "dashes":
                        if let dashes = try Dashes(element: child, words: words) { contents.append(.dashes(dashes)) }
                    case "words":
                        contents.append(.words(try MusicXMLDocument.FormattedText(element: child)))
                        words = child
                        continue
                    case "rehearsal": contents.append(.rehearsal(try MusicXMLDocument.FormattedText(element: child)))
                    case "segno": contents.append(.segno)
                    case "coda": contents.append(.coda)
                    case "pedal": contents.append(.pedal(try Pedal(element: child)))
                    case "bracket": contents.append(.bracket(try Bracket(element: child)))
                    default: contents.append(.unknown(child.name))
                    }
                    words = nil
                }
            }

            self.contents = contents
            self.sound = try element.withOptionalChild(named: "sound", Sound.init)
            self.staff = try element.withOptionalChild(named: "staff", AEXMLElement.asIntContainer)
            self.placement = try element.optionalEnumAttribute("placement")
            self.voice = try element.withOptionalChild(named: "voice", AEXMLElement.asIntContainer)
            self.offset = try element.withOptionalChild(named: "offset", AEXMLElement.asDoubleContainer)
        }

        public init(contents: [MusicXMLDocument.Measure.Direction.Content], sound: MusicXMLDocument.Measure.Direction.Sound? = nil, staff: Int? = nil, placement: MusicXMLDocument.Placement? = nil, voice: Int? = nil, offset: Double? = nil) {
            self.contents = contents
            self.sound = sound
            self.staff = staff
            self.placement = placement
            self.voice = voice
            self.offset = offset
        }
        

        public struct Metronome {

            public let beatUnit: MusicXMLDocument.Note.NoteType
            public let dots: Int
            public let rhs: RHS?

            public enum RHS {
                case perMinute(Int)
                case beat(beatUnit: MusicXMLDocument.Note.NoteType, dots: Int)
            }

            init(element: AEXMLElement) throws(ParseError) {
                var iterator = element.children.makeIterator()
                guard let beatUnitElement = iterator.next() else { throw .invalidChildCount(expected: 1, actual: 0) }
                guard beatUnitElement.name == "beat-unit" else {
                    throw .childNodeError(name: "beat-unit", error: .noSuchChild(name: "beat-unit"))
                }
                do throws(ParseError) {
                    self.beatUnit = try beatUnitElement.asEnumContainer()
                } catch {
                    throw .childNodeError(name: "beat-unit", error: error)
                }

                var dots = 0
                var next = iterator.next()
                while next?.name == "beat-unit-dot" {
                    dots += 1
                    next = iterator.next()
                }
                self.dots = dots

                while next?.name == "beat-unit-tied" { // skip this
                    next = iterator.next()
                }

                guard let next else { throw .invalidChildCount(expected: 2, actual: 1) }
                if next.name == "per-minute" {
                    self.rhs = (try? next.asIntContainer()).map({ .perMinute($0) })
                } else if next.name == "beat-unit", let rhsBeatUnit: MusicXMLDocument.Note.NoteType = try? next.asEnumContainer() {

                    var dots = 0
                    var next = iterator.next()
                    while next?.name == "beat-unit-dot" {
                        dots += 1
                        next = iterator.next()
                    }

                    self.rhs = .beat(beatUnit: rhsBeatUnit, dots: dots)
                } else {
                    self.rhs = nil
                }
            }
            
            public init(beatUnit: MusicXMLDocument.Note.NoteType, dots: Int, rhs: MusicXMLDocument.Measure.Direction.Metronome.RHS? = nil) {
                self.beatUnit = beatUnit
                self.dots = dots
                self.rhs = rhs
            }
        }
        
        public struct Sound {
            public let tempo: Int?
            /// Aka, velocity
            public let dynamics: Double?
            
            init(element: AEXMLElement) throws(ParseError) {
                assert(element.name == "sound")
                self.tempo = try? element.attribute(named: "tempo")
                self.dynamics = try? element.attribute(named: "dynamics")
            }

            public init(tempo: Int? = nil, dynamics: Double? = nil) {
                self.tempo = tempo
                self.dynamics = dynamics
            }
        }
        
        public struct OctaveShift {
            public let phase: StartStopContinue
            /// Positive for up, negative for down. for example, 1 means 8va.
            ///
            /// If `nil`, use previous value.
            public let shift: Int?
            
            /// Distinguishes multiple octave shifts when they overlap in MusicXML document order.
            public let number: Int?
            
            init(element: AEXMLElement) throws(ParseError) {
                assert(element.name == "octave-shift")
                let type: String = try element.attribute(named: "type")
                
                var signum: Int? = nil
                let phase: StartStopContinue
                
                switch type {
                case "up":
                    phase = .start
                    signum = 1
                case "down":
                    phase = .start
                    signum = -1
                case "stop":
                    phase = .stop
                case "continue":
                    phase = .continue
                default:
                    throw ParseError.invalidValue(actual: type, acceptableValues: ["up", "down", "stop", "continue"])
                }
                
                let shift: Int
                let size: String? = try? element.attribute(named: "size")
                switch size {
                case "8": shift = 1
                case "15": shift = 2
                case "22": shift = 3
                default: shift = 1
                }
                
                self.phase = phase
                self.shift = signum.map({ $0 * shift })
                
                self.number = try? element.attribute(named: "number")
            }

            public init(phase: StartStopContinue, shift: Int? = nil, number: Int? = nil) {
                self.phase = phase
                self.shift = shift
                self.number = number
            }
        }
        
        public struct Wedge {
            
            /// The value is crescendo for the start of a wedge that is closed at the left side, diminuendo for the start of a wedge that is closed on the right side, and stop for the end of a wedge.
            public let type: WedgeType
            
            init(element: AEXMLElement) throws(ParseError) {
                assert(element.name == "wedge")
                
                self.type = try element.attribute(named: "type")
            }
            
            public init(type: WedgeType) {
                self.type = type
            }
            
            public enum WedgeType: String, CaseIterable {
                case crescendo, diminuendo, stop, `continue`
            }
            
        }
        
        public struct Dynamics {
            
            public let values: [String]
            
            init(element: AEXMLElement) throws(ParseError) {
                assert(element.name == "dynamics")
                
                self.values = element.children.map(\.name)
            }
            
            public init(values: [String]) {
                self.values = values
            }
        }
        
        public struct Dashes {
            
            public let type: StartStopContinue
            
            public let value: Value?
            
            /// Distinguishes multiple dashes when they overlap in MusicXML document order.
            public let number: Int?
            
            init?(element: AEXMLElement, words: AEXMLElement?) throws(ParseError) {
                assert(element.name == "dashes")
                assert(words.isNil(or: { $0.name == "words" }))
                
                self.type = try element.attribute(named: "type")
                self.value = try? words?.asEnumContainer()
                self.number = try element.optionalAttribute("number")
            }
            
            public init(type: StartStopContinue, value: Value? = nil, number: Int? = nil) {
                self.type = type
                self.value = value
                self.number = number
            }
            
            public enum Value: String, CaseIterable {
                case cresc = "cresc."
                case dim = "dim."
                case rit = "rit."
                case riten = "riten."
                case rall = "rall."
                case accel = "accel."
            }
            
        }
    }
}


extension MusicXMLDocument.Measure.Direction: DetailedStringConvertible {

    public func detailedDescription(using descriptor: DetailedDescription.Descriptor<MusicXMLDocument.Measure.Direction>) -> any DescriptionBlockProtocol {
        descriptor.container {
            descriptor.forEach(self.contents) { content in
                switch content {
                case .metronome(let metronome):
                    descriptor.container("metronome") {
                        descriptor.value("beatUnit", of: metronome.beatUnit)
                        if metronome.dots != 0 {
                            descriptor.value("dots", of: metronome.dots)
                        }
                        if let rhs = metronome.rhs {
                            switch rhs {
                            case .perMinute(let int):
                                descriptor.value("per minute", of: int)
                            case .beat(let beatUnit, let dots):
                                descriptor.value("beatUnit", of: beatUnit)
                                if dots != 0 {
                                    descriptor.value("dots", of: dots)
                                }
                            }
                        }
                    }
                case .octaveShift(let shift):
                    descriptor.constant("\(shift)")
                case .wedge(let wedge):
                    descriptor.constant("\(wedge)")
                case .dynamics(let dynamics):
                    descriptor.constant("\(dynamics)")
                case .dashes(let dashes):
                    descriptor.constant("\(dashes)")
                case .words(let text), .rehearsal(let text):
                    descriptor.constant(text.text)
                case .segno: descriptor.constant("segno")
                case .coda: descriptor.constant("coda")
                case .pedal(let pedal): descriptor.constant("\(pedal)")
                case .bracket(let bracket): descriptor.constant("\(bracket)")
                case .unknown(let unknown):
                    descriptor.constant("unknown(\(unknown))")
                }
            }
            descriptor.optional(for: \.sound)
        }
    }
}
