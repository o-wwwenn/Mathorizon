import SwiftUI

enum AppFontRegistry {
    // Keep this off until a designer has fully completed the font onboarding
    // steps in `Resourses/Fonts/FONT_SETUP.md`. With this set to `false`, both
    // app builds and SwiftUI Preview continue to use safe system fonts.
    static let usesCustomFonts = true

    enum Home {
        // Replace these PostScript names only after the chosen font has been:
        // 1. Added to the app target
        // 2. Verified to load in the running app
        // 3. Verified to render correctly in Preview
        static let chineseRegularPostScriptName = "GenSenRounded2TW-R"
        static let chineseBoldPostScriptName = "GenSenRounded2TW-R"

        static func compactCardTitle(size: CGFloat) -> Font {
            if usesCustomFonts {
                return .custom(chineseBoldPostScriptName, size: size, relativeTo: .headline)
            } else {
                return .system(size: size, weight: .bold, design: .rounded)
            }
        }

        static func largeCardTitle(size: CGFloat) -> Font {
            if usesCustomFonts {
                return .custom(chineseBoldPostScriptName, size: size, relativeTo: .title2)
            } else {
                return .system(size: size, weight: .black, design: .rounded)
            }
        }
    }
}
