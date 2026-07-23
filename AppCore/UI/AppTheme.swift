import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Centralized app typography and theme hooks.
enum AppTheme {
    /// Replace with the internal PostScript family name after validating on device logs.
    static let primaryFontName = "EtihadAltis-Text"

    static func bootstrap() {
        #if canImport(UIKit)
        // Apply to navigation bars. Other UI elements can use AppFont helpers below.
        let navAttributes: [NSAttributedString.Key: Any] = [
            .font: AppFont.uiFont(.title)
        ]

        UINavigationBar.appearance().titleTextAttributes = navAttributes
        UINavigationBar.appearance().largeTitleTextAttributes = navAttributes
        #endif
    }

    static func validateFontRegistration() {
        #if canImport(UIKit)
        let familyNames = UIFont.familyNames.sorted()
        let matchingFamilies = familyNames.filter { $0.localizedCaseInsensitiveContains("Etihad") || $0.localizedCaseInsensitiveContains("Altis") }
        print("[AppTheme] Matching font families: \(matchingFamilies)")

        for family in matchingFamilies {
            let names = UIFont.fontNames(forFamilyName: family)
            print("[AppTheme] Font names for \(family): \(names)")
        }
        #endif
    }
}

enum AppFontStyle {
    case title
    case body
    case caption
}

enum AppFont {
    static func swiftUIFont(_ style: AppFontStyle) -> Font {
        switch style {
        case .title:
            return .custom(AppTheme.primaryFontName, size: 22, relativeTo: .title2)
        case .body:
            return .custom(AppTheme.primaryFontName, size: 16, relativeTo: .body)
        case .caption:
            return .custom(AppTheme.primaryFontName, size: 13, relativeTo: .caption)
        }
    }

    #if canImport(UIKit)
    static func uiFont(_ style: AppFontStyle) -> UIFont {
        switch style {
        case .title:
            return UIFont(name: AppTheme.primaryFontName, size: 22) ?? .boldSystemFont(ofSize: 22)
        case .body:
            return UIFont(name: AppTheme.primaryFontName, size: 16) ?? .systemFont(ofSize: 16)
        case .caption:
            return UIFont(name: AppTheme.primaryFontName, size: 13) ?? .systemFont(ofSize: 13)
        }
    }
    #endif
}

extension View {
    func appFont(_ style: AppFontStyle) -> some View {
        self.font(AppFont.swiftUIFont(style))
    }
}
