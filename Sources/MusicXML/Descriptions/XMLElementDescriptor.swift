//
//  XMLElementDescriptor.swift
//  MusicXML
//
//  Created by Vaida on 2026-03-24.
//

import Foundation
import DetailedDescription

extension XMLElement {
    
    public func description(configuration: XMLElementDescriptor.DescriptionConfiguration) -> String {
        XMLElementDescriptor(root: self).detailedDescription(configuration: configuration)
    }
    
    
    public struct XMLElementDescriptor: DetailedStringConvertibleWithConfiguration {
        
        let root: XMLElement
        
        public func detailedDescription(
            using descriptor: DetailedDescription.Descriptor<XMLElementDescriptor>,
            configuration: DescriptionConfiguration
        ) -> any DescriptionBlockProtocol {
            descriptor.container((root.name ?? "") + " " + "(\(root.kind.description))") {
                descriptor.optional(for: \.root.attributes)
                
                if configuration.contains(.enumerated), let children = root.children {
                    descriptor.forEach(children) { child in
                        if let element = child as? XMLElement {
                            descriptor.value("", of: XMLElementDescriptor(root: element))
                        } else {
                            descriptor.value("", of: child)
                        }
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
