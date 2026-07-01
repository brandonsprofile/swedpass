//  ─────────────────────────────────────────────────────────────
//  Swedpass — portfolio excerpt (not the full application)
//  Shown to illustrate the design/architecture decisions in the README.
//  © Brandon. All rights reserved.
//  ─────────────────────────────────────────────────────────────

import Foundation

/// What a session should contain. All modes route through `SessionBuilder`
/// via one of these scopes — there is no per-mode session assembly elsewhere.
enum SessionScope: Equatable {
    case practiceArea(ContentArea)   // single topic, up to 60 Q from that area
    case practiceAllTopics           // tiered 8/6/4, up to 60 Q
    case realTest                    // tiered 8/6/4, up to 60 Q (timed elsewhere)
    case explicit([UUID])            // Saved — caller supplies the exact IDs

    var mode: SessionMode {
        switch self {
        case .practiceArea, .practiceAllTopics: return .practice
        case .realTest:                          return .realTest
        case .explicit:                          return .practice // overridden by caller; see build(_:mode:)
        }
    }

    /// Whether completion shows the scored `ResultView` (area breakdown) vs. the
    /// plain "Good study session" screen. All-topics Practice and Exam are scored;
    /// single-topic Practice and Saved are not. (Exam is also forced scored in
    /// `QuizSession.init`; both agree.)
    var scored: Bool {
        switch self {
        case .practiceAllTopics, .realTest: return true
        case .practiceArea, .explicit:      return false
        }
    }

    /// Max questions this scope yields. Single source of truth for the cap.
    /// - Exam: always the full 60 (paid-only card; free never reaches it).
    /// - Single-topic Practice: always 10. Free vs paid differ in SELECTION,
    ///   not count — see `randomized(isPremium:)`. Free gets the same fixed 10;
    ///   paid gets a random 10 from the full topic pool.
    /// - All-topics Practice: 60 (paid-only card; free never reaches it).
    /// - Saved (explicit): uncapped — it's the user's own hand-picked set. (Parked.)
    func questionLimit(isPremium: Bool) -> Int {
        switch self {
        case .realTest:          return 60
        case .practiceArea:      return 10
        case .practiceAllTopics: return 60
        case .explicit:          return SessionBuilder.maxQuestions
        }
    }

    /// Whether the draw is randomized for this entitlement.
    ///
    /// The free tier's single-topic quiz (Course → Start Quiz, and Bite Size) is
    /// the sampler: a free user must get the **same fixed 10 questions in the
    /// same order, every time**. So a free single-topic draw is NOT randomized.
    /// Paid unlocks the full pool with a fresh random 10 each run. All other
    /// scopes (all-topics, Exam) are paid-only and always randomized.
    func randomized(isPremium: Bool) -> Bool {
        switch self {
        case .practiceArea: return isPremium
        default:            return true
        }
    }
}

/// Builds the ordered question set for a session.
///
/// Rules (from the roadmap):
/// - Tiered scopes sample each area to `testQuestionCount`, capping at what the
///   bank actually holds (so a thin bank yields fewer, never a crash).
/// - Single-area scope draws up to 60 from that area.
/// - The whole set is **shuffled once** here; callers then treat positions as fixed.
struct SessionBuilder {
    static let maxQuestions = 60

    let bank: [Question]

    init(bank: [Question]) {
        // Only valid questions ever reach a session (quality gate).
        self.bank = bank.filter(\.isValid)
    }

    /// Deterministic when a seeded RNG is passed (tests); random in production.
    ///
    /// `limit` caps how many questions the session holds.
    /// `randomized` controls shuffling: when `false` (free single-topic) the
    /// draw is the bank's first `limit` questions for the area, in bank order —
    /// so a free user gets the SAME fixed set+order every time. When `true`
    /// (paid, and all other scopes) the set is shuffled once, as before.
    /// Defaults preserve the old behavior for unspecified callers.
    func build<R: RandomNumberGenerator>(
        _ scope: SessionScope,
        limit: Int = SessionBuilder.maxQuestions,
        randomized: Bool = true,
        using rng: inout R
    ) -> [Question] {
        switch scope {
        case .practiceArea(let area):
            let pool = questions(in: area)
            // Free: fixed first `limit` in bank order, no shuffle (the sampler).
            // Paid: random `limit` from the full topic pool.
            let ordered = randomized ? pool.shuffled(using: &rng) : pool
            return Array(ordered.prefix(limit))

        case .practiceAllTopics, .realTest:
            return Array(tieredDraw(using: &rng).prefix(limit))

        case .explicit(let ids):
            // Preserve nothing about order — Saved is shuffled per session too.
            let byID = Dictionary(bank.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            return Array(ids.compactMap { byID[$0] }.shuffled(using: &rng).prefix(limit))
        }
    }

    /// Production convenience — uses the system RNG.
    func build(_ scope: SessionScope, limit: Int = SessionBuilder.maxQuestions, randomized: Bool = true) -> [Question] {
        var rng = SystemRandomNumberGenerator()
        return build(scope, limit: limit, randomized: randomized, using: &rng)
    }

    // MARK: - Internals

    private func questions(in area: ContentArea) -> [Question] {
        bank.filter { $0.area == area }
    }

    /// Sample each area to its target count (capped by availability), then shuffle
    /// the combined set so areas are interleaved, not blocked.
    private func tieredDraw<R: RandomNumberGenerator>(using rng: inout R) -> [Question] {
        var drawn: [Question] = []
        for area in ContentArea.allCases {
            let target = area.testQuestionCount
            let available = questions(in: area).shuffled(using: &rng)
            drawn.append(contentsOf: available.prefix(target))
        }
        return drawn.shuffled(using: &rng)
    }
}
