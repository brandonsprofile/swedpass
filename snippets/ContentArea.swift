//  ─────────────────────────────────────────────────────────────
//  Swedpass — portfolio excerpt (not the full application)
//  Shown to illustrate the design/architecture decisions in the README.
//  © Brandon. All rights reserved.
//  ─────────────────────────────────────────────────────────────

import Foundation

/// The 10 official UHR syllabus areas — the pure domain enum (Foundation only,
/// so the engine that depends on it never links SwiftUI). Visual helpers
/// (gradient asset, SF symbol, color) live in `ContentArea+Presentation.swift`.
///
/// English everywhere — `displayName` is what the UI shows (result breakdown,
/// area picker, topic lists). Swedish is kept only as a reference pointer to the
/// source syllabus (in the roadmap, not in code). Raw values are the stable keys
/// used in JSON (and the parked SwiftData layer).
enum ContentArea: String, CaseIterable, Codable, Identifiable {
    case democracy
    case legalSystem
    case humanRights
    case welfareState
    case authorities
    case labourMarket
    case economy
    case familyLife
    case history
    case geography

    var id: String { rawValue }

    /// Short label shown in lists (Courses, topic pickers) where space is tight.
    var displayName: String {
        switch self {
        case .democracy:    return "Democracy"
        case .legalSystem:  return "The Constitution"
        case .humanRights:  return "Human Rights"
        case .welfareState: return "Welfare"
        case .authorities:  return "Authorities"
        case .labourMarket: return "Work & Labor"
        case .economy:      return "Economy"
        case .familyLife:   return "Everyday Society"
        case .history:      return "History"
        case .geography:    return "Geography"
        }
    }

    // MARK: - Real Test composition (single source of truth)

    /// How many questions this area contributes to a 60-question Real Test.
    ///
    /// Civic-priority tiers (High 8 / Med 6 / Low 4), NOT an equal split.
    /// UHR has not published the real distribution — when it does, edit these
    /// numbers, not the session-building code. The launch assertion enforces Σ=60.
    var testQuestionCount: Int {
        switch self {
        case .democracy, .humanRights, .welfareState:
            return 8  // High
        case .legalSystem, .authorities, .labourMarket, .familyLife:
            return 6  // Med
        case .economy, .history, .geography:
            return 4  // Low
        }
    }
}
