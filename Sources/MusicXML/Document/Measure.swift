//
//  Measure.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import AEXML
import DetailedDescription
import MacroCollection


extension MusicXMLDocument {

    /// Includes the basic musical data
    public struct Measure {

        /// The attribute that identifies the measure.
        public let number: String

        public let attributes: Attributes?

        public let contents: [Content]

        init(element: AEXMLElement) throws(ParseError) {
            assert(element.name == "measure")
            self.number = try element.attribute(named: "number", as: String.self)

            var contents: [Content] = []
            for (index, child) in element.children.enumerated() {
                do {
                    switch child.name {
                    case "note":
                        guard let note = try Note(element: child) else { continue } // ignore notes that dont produce a sound
                        contents.append(.note(note))

                    case "backup":
                        let duration = try child.withChild(named: "duration", AEXMLElement.asIntContainer)
                        contents.append(.backup(duration: duration))

                    case "barline":
                        let barline = try BarLine(element: child)
                        contents.append(.barline(barline))

                    case "direction":
                        guard let direction = try Direction(element: child) else { continue }
                        contents.append(.direction(direction))

                    case "attributes": // will be handled in the following lines.
                        continue

                    case "print": // layout properties, ignore.
                        continue

                    default:
                        contents.append(.unknown(child.name))
                    }
                } catch {
                    throw .childNodeError(name: "[\(index)] (\(child.name))", error: error)
                }
            }
            self.contents = contents

            self.attributes = try element.withOptionalChild(named: "attributes", Attributes.init)
        }

        @accessingAssociatedValues
        public enum Content {
            case note(MusicXMLDocument.Note)
            case unknown(String)
            case backup(duration: Int)
            case barline(BarLine)
            case direction(Direction)
        }

    }

}

extension MusicXMLDocument.Measure.Content: CustomStringConvertible {
    public var description: String {
        switch self {
        case .note(let note): note.debugDescription
        case .backup(let duration): "backup(\(duration))"
        case .unknown(let name): "unknown(\(name))"
        case .barline(let barline): barline.debugDescription
        case .direction(let direction): direction.debugDescription
        }
    }
}


extension MusicXMLDocument.Measure: DetailedStringConvertible {

    public func detailedDescription(using descriptor: DetailedDescription.Descriptor<MusicXMLDocument.Measure>) -> any DescriptionBlockProtocol {
        descriptor.container("measure #\(number)") {
            descriptor.optional(for: \.attributes)
            descriptor.sequence(for: \.contents)
        }
    }

}
