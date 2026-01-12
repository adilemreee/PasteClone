//
//  Color+Theme.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI

// MARK: - App Colors

extension Color {
    // MARK: - Brand Colors
    
    /// Primary brand color
    static let brandPrimary = Color("BrandPrimary", bundle: nil) 
    
    /// Secondary brand color
    static let brandSecondary = Color("BrandSecondary", bundle: nil) 
    
    // MARK: - Semantic Colors
    
    /// Background color for cards
    static let cardBackground = Color(.secondarySystemBackground)
    
    /// Elevated background for overlays
    static let elevatedBackground = Color(.tertiarySystemBackground)
    
    /// Grouped content background
    static let groupedBackground = Color(.systemGroupedBackground)
    
    // MARK: - Type Colors
    
    /// Color for text clipboard items
    static let textItemColor = Color.blue
    
    /// Color for image clipboard items
    static let imageItemColor = Color.purple
    
    /// Color for link clipboard items
    static let linkItemColor = Color.green
    
    /// Color for file clipboard items
    static let fileItemColor = Color.orange
    
    // MARK: - Status Colors
    
    /// Success/positive color
    static let success = Color.green
    
    /// Warning color
    static let warning = Color.orange
    
    /// Error/destructive color
    static let destructive = Color.red
    
    /// Info color
    static let info = Color.blue
}

// MARK: - Gradient Definitions

extension LinearGradient {
    /// Primary brand gradient
    static let brandGradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Sunset gradient
    static let sunsetGradient = LinearGradient(
        colors: [.orange, .pink, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Ocean gradient
    static let oceanGradient = LinearGradient(
        colors: [.cyan, .blue, .indigo],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Forest gradient
    static let forestGradient = LinearGradient(
        colors: [.green, .teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Shimmer gradient for loading states
    static let shimmerGradient = LinearGradient(
        colors: [
            Color.gray.opacity(0.3),
            Color.gray.opacity(0.1),
            Color.gray.opacity(0.3)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Theme Provider

enum AppColorScheme {
    case light
    case dark
    case system
}

@Observable
final class ThemeManager {
    static let shared = ThemeManager()
    
    var currentTheme: AppTheme = .system
    
    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }
    
    /// Get appropriate color for current theme
    func adaptiveColor(light: Color, dark: Color) -> Color {
        switch currentTheme {
        case .light:
            return light
        case .dark, .liquidGlass:
            return dark
        case .system:
            return Color(.label) // Will adapt automatically
        }
    }
}

// MARK: - Color Utilities

extension Color {
    /// Create color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Lighten color by percentage
    func lighter(by percentage: CGFloat = 0.2) -> Color {
        return self.opacity(1 - percentage)
    }
    
    /// Darken color by percentage
    func darker(by percentage: CGFloat = 0.2) -> Color {
        return self.opacity(1 + percentage)
    }
}

// MARK: - Pinboard Colors

extension Color {
    /// Get color for pinboard by name
    static func pinboardColor(_ name: String) -> Color {
        switch name {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "cyan": return .cyan
        default: return .blue
        }
    }
    
    /// All available pinboard colors
    static let pinboardColors: [(name: String, color: Color)] = [
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green),
        ("teal", .teal),
        ("cyan", .cyan),
        ("blue", .blue),
        ("indigo", .indigo),
        ("purple", .purple),
        ("pink", .pink)
    ]
}
