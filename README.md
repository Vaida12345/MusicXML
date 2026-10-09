# MusicXML

Read MusicXML/MXL files or construct immutable score values and export them.

```swift
import MusicXML
import FinderItem

let note = MusicXMLDocument.Note(
    id: 0,
    pitch: .init(step: .C, octave: 4),
    duration: 4,
    type: .whole
)
let measure = MusicXMLDocument.Measure(
    number: "1",
    attributes: .init(
        divisions: 1,
        timeSignature: .init(beats: 4, beatType: 4),
        clef: .init(sign: .treble, line: 2)
    ),
    contents: [.note(note)]
)
let score = MusicXMLDocument(
    partList: .init(scores: [.init(id: "P1", name: "Piano")]),
    parts: [.init(id: "P1", measures: [measure])],
    title: "Study",
    composer: "Composer"
)

try score.write(to: FinderItem(at: "/tmp/Study.mxl"))
try score.write(to: FinderItem(at: "/tmp/Study.musicxml"), format: .musicxml)
```

`MusicXMLDocument.ExportFormat` supports `.mxl` (default) and `.musicxml`.
The destination's extension does not determine the format. Writing replaces an
existing file atomically; I/O and compression errors propagate to the caller.
Export uses MusicXML 4.0 when the document's version is unspecified.

All public structs have public construction initializers. Construct scores from
your own model using these values; no mutation or read-before-write step is needed.

Supported additions include:

- Notes: whole-measure rests, unpitched notes, and lyrics with syllabic and extension marks.
- Notations: slurs, articulations, ornaments (including tremolos), graphical tuplets,
  and multiple arpeggiations/glissandos. Playback ties also generate visible tied marks.
- Directions: formatted words, rehearsal marks, segno/coda, pedal, brackets,
  placement, voice, and offsets, alongside the existing direction types.
- Metadata: title, composer, and page credits with formatted and positioned text.
- Layout: page dimensions/margins, system margins/spacing, staff spacing, scaling,
  fonts, line widths, note sizes, and local `Measure.Content.print` instructions.

`Layout` contains score-wide defaults. Use `.print(.init(newSystem: true))` or
`.print(.init(newPage: true))` at the start of a measure for explicit breaks;
`Print` also supports local layout, page numbering, blank pages, measure spacing,
and measure numbering. Distances use MusicXML tenths (one tenth of a staff space),
with `Layout.Scaling` relating tenths to millimeters. Specify page width and height
together when setting page dimensions.

Title/composer metadata and visible credits are separate. To explicitly place text
on a page, supply `Credit` values containing `FormattedText` with optional fonts,
coordinates, justification, and vertical alignment.

The model keeps one attributes block and one clef/time signature per measure.
There is no part-group model. Existing simplified values are retained.
`Notations.arpeggiate` and `.glissando` expose the first mark for convenience;
use `.arpeggiations` and `.glissandos` for collections.

Writing serializes the supplied values without runtime musical/schema validation.
Unknown name-only placeholders are omitted. Export is intended for generating
scores, and does not preserve unmodeled information from imported documents.

Run the self-contained reader and export tests:

```sh
swift test --filter 'WriterTests|example'
```

On macOS, optionally check generated XML with `xmllint` against a local copy of the
[official MusicXML 4.0 schema](https://github.com/w3c/musicxml/tree/v4.0/schema):

```sh
MUSICXML_SCHEMA_PATH=/path/to/musicxml.xsd swift test --filter WriterTests
```

Make the schema's `xml.xsd` and `xlink.xsd` imports resolve locally (for example,
with relative `schemaLocation` paths). The original file/dataset tests require
external reference files at their specified local paths.
