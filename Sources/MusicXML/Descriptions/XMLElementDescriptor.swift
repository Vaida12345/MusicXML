//
//  XMLElementDescriptor.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import AEXML
import DetailedDescription

extension AEXMLElement {

    public func description(configuration: XMLElementDescriptor.DescriptionConfiguration) -> String {
        XMLElementDescriptor(root: self).detailedDescription(configuration: configuration)
    }


    public struct XMLElementDescriptor: DetailedStringConvertibleWithConfiguration {

        let root: AEXMLElement

        public func detailedDescription(
            using descriptor: DetailedDescription.Descriptor<XMLElementDescriptor>,
            configuration: DescriptionConfiguration
        ) -> any DescriptionBlockProtocol {
            descriptor.container(root.name + " (element)") {
                if !root.attributes.isEmpty {
                    descriptor.value("attributes", of: root.attributes)
                }
                if let value = root.value, !value.isEmpty {
                    descriptor.value("value", of: value)
                }

                if configuration.contains(.enumerated) {
                    descriptor.forEach(root.children) { child in
                        descriptor.value("", of: XMLElementDescriptor(root: child))
                    }
                }
            }
        }

        public struct DescriptionConfiguration: OptionSet, Initializable, Sendable {
            public let rawValue: UInt8

            public static let enumerated = DescriptionConfiguration(rawValue: 1 << 0)

            public init(rawValue: UInt8) {
                self.rawValue = rawValue
            }
        }

    }

}
