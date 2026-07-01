//  ─────────────────────────────────────────────────────────────
//  Swedpass — portfolio excerpt (not the full application)
//  Shown to illustrate the design/architecture decisions in the README.
//  © Brandon. All rights reserved.
//  ─────────────────────────────────────────────────────────────

import SwiftUI
import UIKit   // UIColor (dynamic light/dark background)

/// Two-tier design-token system.
///
/// **Tier 1 — primitives** (`Space`): the raw scale. Not consumed by screens.
/// **Tier 2 — semantic** (`Layout`, `Size`): named by ROLE, mapped to primitives.
///
/// Screens use ONLY Tier 2. Change a semantic token here and every screen that
/// plays that role updates at once — no hunting raw numbers across files.
enum Theme {

    // MARK: - Tier 1: Primitive spacing scale (internal)

    /// Raw spacing steps. Prefer a semantic `Layout` token in views; reach for a
    /// primitive only when no semantic role fits.
    enum Space {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
    }

    // MARK: - Tier 2: Semantic layout (what screens consume)

    /// Spacing named by the job it does on a screen. This is the layer to edit
    /// when you want a layout relationship to change app-wide.
    enum Layout {
        /// Left/right margin between content and the screen edges.
        static let screenMargin = Space.lg          // 24
        /// Gap between a title and the content block beneath it.
        static let titleToContent = Space.md        // 16
        /// Tight pairing gap (e.g. a label sitting just above its button).
        static let tightGap = Space.xs              // 8
        /// Gap between stacked action buttons (primary over secondary). Tight,
        /// matching Apple's system pattern (e.g. the iCloud+ paywall buttons).
        static let buttonStackGap = Space.xs        // 8
        /// Vertical gap between stacked rows / cards.
        static let rowGap = Space.sm                // 12
        /// Wider gap between grouped rows (e.g. Settings list).
        static let groupGap = Space.lg              // 24
        /// Inner horizontal padding inside a row / card.
        static let rowInset = Space.md              // 16
        /// Generic section separation within a screen.
        static let sectionGap = Space.xxl           // 40
        /// Gap between Home's major sections (Exam Prep / Course / Quick Quizzes)
        /// and the header→first-section gap.
        static let homeSectionGap = Space.xxl       // 40
        /// Side margin for the Quick Quizzes grid — tighter than `screenMargin`
        /// (24) so the square cards sit a touch wider.
        static let quickQuizMargin = Space.md        // 16
        /// Corner radius for `CapsuleRow` (answer pills, Home + Settings rows) —
        /// matches the explanation box so the rows read as one family.
        static let rowCorner = Space.md              // 16
    }

    // MARK: - Tier 2: Semantic sizes

    enum Size {
        /// Capsule menu-row height.
        static let row: CGFloat = 64
    }

    // MARK: - Tier 2: Semantic font sizes

    /// Font point sizes named by ROLE (not by number), so type decisions live in
    /// one place like spacing does. Weight stays at the call site — the same size
    /// serves different weights by context (e.g. `metadata` is medium on a pill,
    /// regular in a blurb). Used as the base for `@ScaledMetric` where a view
    /// scales with Dynamic Type, or directly where it doesn't.
    ///
    /// As with the spacing tokens, distinct roles may share a value (e.g.
    /// `cardTitle`/`tagline` are both 20) — that's intentional, so one role can
    /// later change without dragging the others.
    enum FontSize {
        /// Splash welcome headline.
        static let display: CGFloat = 44
        /// Home section headers ("Exam Prep", "Course", "Quick Quizzes").
        static let sectionHeader: CGFloat = 22
        /// Title on the large Quiz / Course cards.
        static let cardTitle: CGFloat = 20
        /// Splash tagline beneath the wordmark.
        static let tagline: CGFloat = 20
        /// Title on the square Quick Quiz cards.
        static let cardTitleSmall: CGFloat = 17
        /// Body reading size (Splash acknowledgement line).
        static let body: CGFloat = 17
        /// Small supporting text — metadata pills and the Course card blurb.
        static let metadata: CGFloat = 15
    }
}

// MARK: - Chrome sizing

extension View {
    /// Caps Dynamic Type scaling for *chrome* — glass buttons, pills, nav glyphs,
    /// counters, timers. These are controls, not content: like Apple's own
    /// toolbar/tab-bar items, they should stay roughly size-stable so layout never
    /// breaks at large accessibility text. Content (questions, answers, theory,
    /// result text) is NOT capped — it must scale fully for accessibility.
    ///
    /// Scales normally up through `.large`, then holds. Apply to chrome only.
    func chromeFixed() -> some View {
        dynamicTypeSize(...DynamicTypeSize.large)
    }

    /// Background fade for a floating TOP bar (X / counter / timer chrome): solid
    /// `appBackground` at the top easing to clear at the bottom, so content
    /// scrolling beneath the bar dissolves cleanly instead of bleeding around the
    /// glyphs. Used by `QuestionView` and `ResultView`.
    func topFadeBar() -> some View {
        background(
            LinearGradient(
                colors: [Color.appBackground, Color.appBackground, Color.appBackground.opacity(0)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    /// Background fade for a floating BOTTOM bar (nav / action buttons): the
    /// mirror of `topFadeBar` — clear at the top easing to solid at the bottom.
    func bottomFadeBar() -> some View {
        background(
            LinearGradient(
                colors: [Color.appBackground.opacity(0), Color.appBackground, Color.appBackground],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Semantic colors

/// Role-named colors backed by native semantic system colors (so dark mode and
/// contrast come for free). Screens use these, not raw `Color(.system…)`.
extension Color {
    /// App screen background (#F2F2F7 in light).
    ///
    /// Paired with `cardFill` from the SAME (grouped) hierarchy so a card always
    /// reads as a distinct layer above the page in BOTH modes. The previous
    /// pairing mixed hierarchies (`secondarySystemBackground` here +
    /// `secondarySystemGroupedBackground` for the card), whose dark-mode values
    /// collapse to nearly the same near-black — making the capsule edge vanish.
    /// Subtle warm off-white in LIGHT mode; the unchanged system value in DARK.
    /// Dynamic (not a fixed hex) so dark mode and contrast are preserved exactly
    /// — only the light-mode page tone warms slightly off pure system gray.
    /// Cards (`cardFill`, still white in light) read as a more distinct layer
    /// against the tint. Try-and-test; revert to `Color(.systemGroupedBackground)`
    /// if it doesn't hold up on-device.
    static let appBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.systemGroupedBackground                       // dark: untouched
            : UIColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1) // light: warm off-white #F5F2EB
    })
    /// Fill for cards / capsule rows sitting on `appBackground`. One step lighter
    /// than the page in both modes (white in light). This is the iOS Settings
    /// pairing: `systemGroupedBackground` page + `secondarySystemGroupedBackground`
    /// cells.
    static let cardFill = Color(.secondarySystemGroupedBackground)
}
