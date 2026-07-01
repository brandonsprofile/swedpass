//  ─────────────────────────────────────────────────────────────
//  Swedpass — portfolio excerpt (not the full application)
//  Shown to illustrate the design/architecture decisions in the README.
//  © Brandon. All rights reserved.
//  ─────────────────────────────────────────────────────────────

import Foundation

/// The ways a session can be entered. Drives both behavior (via `config`)
/// and completion routing (scored result vs. plain "good session" screen).
enum SessionMode: String, Codable {
    case practice      // single-area or all-topics, up to 60 Q
    case realTest      // "Exam" — tiered 60 Q, timed
    case saved         // manual bookmarks, per topic

    var config: ModeConfig {
        switch self {
        case .practice:  return .practice
        case .realTest:  return .realTest
        case .saved:     return .saved
        }
    }
}

/// Per-mode UI rules. One QuestionView reads this instead of branching on mode
/// everywhere. Skip never reorders (questions hold fixed slots within a session),
/// so there is no requeue flag.
struct ModeConfig: Equatable {
    /// Timed-mode settings. `nil` for untimed modes — so `showsTimer` is just
    /// "has timing," and the duration/warning live here rather than as loose
    /// constants in the view. The single source of truth for the exam clock.
    struct Timing: Equatable {
        let duration: TimeInterval   // total countdown
        let warning: TimeInterval    // timer turns red at/below this many seconds left

        /// Whole-minute label for the duration (e.g. "90 min"), so the countdown
        /// and the Home pill agree without hand-typing the number twice.
        var minutesLabel: String { "\(Int(duration / 60)) min" }
    }

    let timing: Timing?            // non-nil only for timed modes (Exam)
    let immediateFeedback: Bool
    let revealsCorrectness: Bool   // navigator cells: red/green vs. blue-only
    let canReanswer: Bool          // Exam: edit until submit; Practice/Saved: lock on submit
    let hasNavigator: Bool         // grid navigator (Practice/Exam) vs. simple list (Saved)

    /// Whether this mode runs a countdown. Derived — a mode is timed iff it has timing.
    var showsTimer: Bool { timing != nil }

    static let practice = ModeConfig(
        timing: nil, immediateFeedback: true,
        revealsCorrectness: true,  canReanswer: false, hasNavigator: true
    )

    static let realTest = ModeConfig(
        timing: Timing(duration: 90 * 60, warning: 10 * 60), immediateFeedback: false,
        revealsCorrectness: false, canReanswer: true,  hasNavigator: true
    )

    // Saved — simple list, no navigator.
    static let saved = ModeConfig(
        timing: nil, immediateFeedback: true,
        revealsCorrectness: true,  canReanswer: false, hasNavigator: false
    )
}
