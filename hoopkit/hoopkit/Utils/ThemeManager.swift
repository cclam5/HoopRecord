import SwiftUI

enum Theme: String {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("theme") var currentTheme: Theme = .system {
        didSet {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                switch currentTheme {
                case .light:
                    windowScene.windows.first?.overrideUserInterfaceStyle = .light
                case .dark:
                    windowScene.windows.first?.overrideUserInterfaceStyle = .dark
                case .system:
                    windowScene.windows.first?.overrideUserInterfaceStyle = .unspecified
                }
            }
        }
    }
    
    private init() {}
} 