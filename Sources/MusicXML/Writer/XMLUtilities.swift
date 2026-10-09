import AEXML

extension AEXMLElement {
    func mapChildren<T>(named name: String, _ transform: (AEXMLElement) throws(ParseError) -> T) throws(ParseError) -> [T] {
        var result: [T] = []
        try forEachChild(named: name) { (child) throws(ParseError) in
            result.append(try transform(child))
        }
        return result
    }

    func optionalAttribute<T: LosslessStringConvertible>(_ name: String, as type: T.Type = T.self) throws(ParseError) -> T? {
        guard attributes[name] != nil else { return nil }
        return try attribute(named: name, as: type)
    }

    func optionalEnumAttribute<T: RawRepresentable & CaseIterable>(_ name: String, as type: T.Type = T.self) throws(ParseError) -> T? where T.RawValue == String {
        guard attributes[name] != nil else { return nil }
        return try attribute(named: name, as: type)
    }

    func optionalYesNoAttribute(_ name: String) throws(ParseError) -> Bool? {
        guard let value = attributes[name] else { return nil }
        switch value {
        case "yes": return true
        case "no": return false
        default: throw .attributeError(name: name, error: .invalidValue(actual: value, acceptableValues: ["yes", "no"]))
        }
    }

    func setAttribute<T: CustomStringConvertible>(_ name: String, _ value: T?) {
        if let value { attributes[name] = value.description }
    }

    func setEnumAttribute<T: RawRepresentable>(_ name: String, _ value: T?) where T.RawValue == String {
        if let value { attributes[name] = value.rawValue }
    }

    func setYesNoAttribute(_ name: String, _ value: Bool?) {
        if let value { attributes[name] = value ? "yes" : "no" }
    }

    func addValue<T: CustomStringConvertible>(_ name: String, _ value: T?) {
        if let value { addChild(name: name, value: value.description) }
    }

    func addEnum<T: RawRepresentable>(_ name: String, _ value: T?) where T.RawValue == String {
        if let value { addChild(name: name, value: value.rawValue) }
    }

    func addRepeated(_ name: String, count: Int) {
        for _ in 0..<max(0, count) { addChild(name: name) }
    }
}

extension MusicXMLDocument {
    public enum Placement: String, CaseIterable, Sendable {
        case above, below
    }

    public enum LineType: String, CaseIterable, Sendable {
        case solid, dashed, dotted, wavy
    }
}
