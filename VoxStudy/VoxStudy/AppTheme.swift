import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Sistema"
        case .light: return "Claro"
        case .dark: return "Oscuro"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// Los mismos colores se comparten entre el lector y la pantalla de ajustes.
struct AppPalette {
    let background: Color
    let surface: Color
    let accent: Color
    let mainText: Color
    let secondaryText: Color
    let buttonText: Color
    private let isDark: Bool

    var peach: Color {
        isDark ? Color(red: 0.25, green: 0.19, blue: 0.19)
            : Color(red: 0.945, green: 0.855, blue: 0.808)
    }

    var sage: Color {
        isDark ? Color(red: 0.19, green: 0.23, blue: 0.19)
            : Color(red: 0.875, green: 0.906, blue: 0.851)
    }

    var lilac: Color {
        isDark ? Color(red: 0.23, green: 0.19, blue: 0.27)
            : Color(red: 0.914, green: 0.875, blue: 0.953)
    }

    init(colorScheme: ColorScheme) {
        isDark = colorScheme == .dark
        if colorScheme == .dark {
            background = Color(red: 0.125, green: 0.114, blue: 0.129)
            surface = Color(red: 0.173, green: 0.157, blue: 0.176)
            accent = Color(red: 0.780, green: 0.651, blue: 0.929)
            mainText = Color(red: 0.965, green: 0.945, blue: 0.918)
            secondaryText = Color(red: 0.784, green: 0.753, blue: 0.780)
            buttonText = Color(red: 0.169, green: 0.110, blue: 0.212)
        } else {
            background = Color(red: 0.961, green: 0.937, blue: 0.902)
            surface = Color(red: 1, green: 0.984, blue: 0.961)
            accent = Color(red: 0.412, green: 0.263, blue: 0.459)
            mainText = Color(red: 0.188, green: 0.157, blue: 0.188)
            secondaryText = Color(red: 0.439, green: 0.392, blue: 0.427)
            buttonText = .white
        }
    }
}


