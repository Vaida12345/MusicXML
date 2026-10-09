import AEXML

extension MusicXMLDocument.Measure.Direction {
    var xmlElement: AEXMLElement {
        let element = AEXMLElement(name: "direction")
        element.setEnumAttribute("placement", placement)
        var previousWords: String?
        for content in contents {
            if case .unknown = content { continue }
            let container = element.addChild(name: "direction-type")
            switch content {
            case .words(let text):
                container.addChild(text.xmlElement(named: "words"))
                previousWords = text.text
                continue
            case .rehearsal(let text): container.addChild(text.xmlElement(named: "rehearsal"))
            case .segno: container.addChild(name: "segno")
            case .coda: container.addChild(name: "coda")
            case .pedal(let pedal): container.addChild(pedal.xmlElement)
            case .bracket(let bracket): container.addChild(bracket.xmlElement)
            case .metronome(let metronome):
                let mark = container.addChild(name: "metronome")
                mark.addEnum("beat-unit", metronome.beatUnit)
                mark.addRepeated("beat-unit-dot", count: metronome.dots)
                if let rhs = metronome.rhs {
                    switch rhs {
                    case .perMinute(let value): mark.addValue("per-minute", value)
                    case .beat(let type, let dots):
                        mark.addEnum("beat-unit", type)
                        mark.addRepeated("beat-unit-dot", count: dots)
                    }
                }
            case .octaveShift(let octave):
                let type: String
                switch octave.phase {
                case .start: type = (octave.shift ?? 1) < 0 ? "down" : "up"
                case .stop: type = "stop"
                case .continue: type = "continue"
                }
                let mark = container.addChild(name: "octave-shift", attributes: ["type": type])
                mark.setAttribute("number", octave.number)
                if let shift = octave.shift {
                    // One octave is 8, two are 15, and three are 22.
                    mark.setAttribute("size", shift.magnitude * 7 + 1)
                }
            case .wedge(let wedge): container.addChild(name: "wedge", attributes: ["type": wedge.type.rawValue])
            case .dynamics(let dynamics):
                let mark = container.addChild(name: "dynamics")
                for value in dynamics.values { mark.addChild(name: value) }
            case .dashes(let dashes):
                if let value = dashes.value, previousWords != value.rawValue {
                    // Words and dashes are distinct direction-type elements.
                    container.addChild(name: "words", value: value.rawValue)
                    let mark = element.addChild(name: "direction-type").addChild(name: "dashes", attributes: ["type": dashes.type.rawValue])
                    mark.setAttribute("number", dashes.number)
                } else {
                    container.addChild(name: "dashes", attributes: ["type": dashes.type.rawValue]).setAttribute("number", dashes.number)
                }
            case .unknown: break
            }
            previousWords = nil
        }
        element.addValue("offset", offset)
        element.addValue("voice", voice)
        element.addValue("staff", staff)
        if let sound {
            let soundElement = element.addChild(name: "sound")
            soundElement.setAttribute("tempo", sound.tempo)
            soundElement.setAttribute("dynamics", sound.dynamics)
        }
        return element
    }
}
