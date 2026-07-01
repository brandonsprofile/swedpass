# Code excerpts

Four illustrative files from the Swedpass codebase, chosen to back up the
design and architecture decisions described in the [main README](../README.md).

These are **excerpts, not the runnable app** — the full source is private.

| File | What it shows |
|---|---|
| [`ContentArea.swift`](ContentArea.swift) | The 10 syllabus areas as a pure domain enum, with the civic-priority 8/6/4 test weighting kept as a single source of truth (edit the numbers, not the session logic). |
| [`ModeConfig.swift`](ModeConfig.swift) | The "one screen, many modes" pattern: Practice / Exam / Saved expressed as data (timer, feedback, re-answer, navigator) so a single question view never branches on mode. |
| [`SessionBuilder.swift`](SessionBuilder.swift) | The session engine: tiered sampling by area, thin-bank-safe capping, shuffle-once, and a seedable RNG so the logic is deterministically unit-testable. |
| [`Theme.swift`](Theme.swift) | The two-tier design-token system (primitives → semantic roles) plus role-named colors backed by native semantic system colors, so dark mode and contrast come for free. |
