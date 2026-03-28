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
        
        @accessingAssociatedValues
        public enum Content {
            case metronome(Metronome)
            case octaveShift(OctaveShift)
            /// Represents crescendo and diminuendo wedge symbols.
            case wedge(Wedge)
            case dynamics(Dynamics)
            case unknown(String)
        }

        init(element: AEXMLElement) throws(ParseError) {
            assert(element.name == "direction")
            
            var contents: [Content] = []
            for child in element.children where child.name == "direction-type" {
                guard let firstChild = child.children.first else { continue } // exactly one, so first child.
                
                switch firstChild.name {
                case "metronome":
                    let metronome = try Metronome(element: firstChild)
                    contents.append(.metronome(metronome))
                    
                case "octave-shift":
                    let octaveShift = try OctaveShift(element: firstChild)
                    contents.append(.octaveShift(octaveShift))
                    
                case "wedge":
                    let wedge = try Wedge(element: firstChild)
                    contents.append(.wedge(wedge))
                    
                case "dynamics":
                    let dynamics = try Dynamics(element: firstChild)
                    contents.append(.dynamics(dynamics))
                    
                default:
                    contents.append(.unknown(firstChild.name))
                }
            }
            self.contents = contents
            self.sound = try element.withOptionalChild(named: "sound", Sound.init)
            self.staff = try element.withOptionalChild(named: "staff", AEXMLElement.asIntContainer)
        }

        public init(contents: [MusicXMLDocument.Measure.Direction.Content], sound: MusicXMLDocument.Measure.Direction.Sound? = nil, staff: Int? = nil) {
            self.contents = contents
            self.sound = sound
            self.staff = staff
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
                do {
                    guard beatUnitElement.name == "beat-unit" else { throw ParseError.noSuchChild(name: "beat-unit") }
                    self.beatUnit = try beatUnitElement.asEnumContainer()
                } catch {
                    throw .childNodeError(name: "beat-unit", error: error as! ParseError)
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
                                if metronome.dots != 0 {
                                    descriptor.value("dots", of: dots)
                                }
                            }
                        }
                    }
                case .octaveShift(let shift):
                    descriptor.constant("octaveShift(\(shift))")
                case .wedge(let wedge):
                    descriptor.constant("wedge(\(wedge))")
                case .dynamics(let dynamics):
                    descriptor.constant("dynamics(\(dynamics))")
                case .unknown(let unknown):
                    descriptor.constant("unknown(\(unknown))")
                }
            }
            descriptor.optional(for: \.sound)
        }
    }
}
