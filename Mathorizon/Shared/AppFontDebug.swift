import UIKit

enum AppFontDebug {
    // Usage:
    // AppFontDebug.printAllFamilies()
    // AppFontDebug.printMatchingFonts(keyword: "GenSen")
    // AppFontDebug.printMatchingFonts(keyword: "Rounded")
    static func printAllFamilies() {
        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family).sorted() {
                print("  Font: \(name)")
            }
        }
    }

    static func printMatchingFonts(keyword: String) {
        let normalizedKeyword = keyword.lowercased()

        for family in UIFont.familyNames.sorted() {
            let familyMatches = family.lowercased().contains(normalizedKeyword)
            let names = UIFont.fontNames(forFamilyName: family).sorted()
            let matchingNames = names.filter { $0.lowercased().contains(normalizedKeyword) }

            guard familyMatches || !matchingNames.isEmpty else {
                continue
            }

            print("Family: \(family)")
            for name in matchingNames.isEmpty ? names : matchingNames {
                print("  Font: \(name)")
            }
        }
    }
}
