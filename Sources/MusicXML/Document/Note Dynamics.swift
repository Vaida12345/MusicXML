extension MusicXMLDocument.Note {
    /// Nearest MIDI 1.0 velocity, clamped to 0...127. Nil means no note-level dynamics.
    public var midiVelocity: Int? {
        dynamics.map(Self.midiVelocity(forDynamics:))
    }

    /// Converts velocity to a percentage of the MusicXML reference velocity (90).
    public static func dynamics(forMIDIVelocity velocity: Int) -> Double {
        Double(velocity) * 100 / 90
    }

    /// Converts a MusicXML percentage to MIDI 1.0, rounding halfway values away from zero.
    /// Values outside the MIDI range are clamped. NaN maps to 0; infinities clamp to the endpoints.
    public static func midiVelocity(forDynamics dynamics: Double) -> Int {
        guard dynamics > 0 else { return 0 }
        guard dynamics < Double(127) * 100 / 90 else { return 127 }
        return Int((dynamics * 90 / 100).rounded())
    }
}
