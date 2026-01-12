//
//  UserSettings.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import Foundation
import SwiftUI

/// App theme options
enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case liquidGlass = "liquidGlass"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .liquidGlass: return "Liquid Glass"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .liquidGlass: return "drop.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system, .liquidGlass: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// History retention period options
enum HistoryRetention: String, Codable, CaseIterable, Identifiable {
    case oneDay = "1day"
    case oneWeek = "1week"
    case oneMonth = "1month"
    case threeMonths = "3months"
    case sixMonths = "6months"
    case oneYear = "1year"
    case forever = "forever"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .oneDay: return "1 Day"
        case .oneWeek: return "1 Week"
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        case .forever: return "Forever"
        }
    }
    
    var days: Int? {
        switch self {
        case .oneDay: return 1
        case .oneWeek: return 7
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        case .forever: return nil
        }
    }
}

/// User settings manager using AppStorage for persistence
@Observable
final class UserSettings {
    // MARK: - Singleton
    
    static let shared = UserSettings()
    
    // MARK: - Keys
    
    private enum Keys {
        static let syncEnabled = "syncEnabled"
        static let notificationsEnabled = "notificationsEnabled"
        static let theme = "theme"
        static let historyRetention = "historyRetention"
        static let soundEnabled = "soundEnabled"
        static let hapticEnabled = "hapticEnabled"
        static let showPreviews = "showPreviews"
        static let autoDeleteSensitive = "autoDeleteSensitive"
        static let sensitiveDataDelay = "sensitiveDataDelay"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastSyncDate = "lastSyncDate"
        static let ignoredAppIdentifiers = "ignoredAppIdentifiers"
    }
    
    // MARK: - Properties
    
    private let defaults: UserDefaults
    
    /// iCloud sync enabled
    var syncEnabled: Bool {
        didSet { defaults.set(syncEnabled, forKey: Keys.syncEnabled) }
    }
    
    /// Notifications enabled
    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }
    
    /// Current theme
    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }
    
    /// History retention period
    var historyRetention: HistoryRetention {
        didSet { defaults.set(historyRetention.rawValue, forKey: Keys.historyRetention) }
    }
    
    /// Sound effects enabled
    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }
    
    /// Haptic feedback enabled
    var hapticEnabled: Bool {
        didSet { defaults.set(hapticEnabled, forKey: Keys.hapticEnabled) }
    }
    
    /// Show content previews in list
    var showPreviews: Bool {
        didSet { defaults.set(showPreviews, forKey: Keys.showPreviews) }
    }
    
    /// Auto-delete sensitive data
    var autoDeleteSensitive: Bool {
        didSet { defaults.set(autoDeleteSensitive, forKey: Keys.autoDeleteSensitive) }
    }
    
    /// Delay before clearing sensitive data (seconds)
    var sensitiveDataDelay: Int {
        didSet { defaults.set(sensitiveDataDelay, forKey: Keys.sensitiveDataDelay) }
    }
    
    /// Has completed onboarding
    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }
    
    /// Last successful sync date
    var lastSyncDate: Date? {
        didSet {
            if let date = lastSyncDate {
                defaults.set(date, forKey: Keys.lastSyncDate)
            } else {
                defaults.removeObject(forKey: Keys.lastSyncDate)
            }
        }
    }
    
    /// App identifiers to ignore when monitoring clipboard
    var ignoredAppIdentifiers: [String] {
        didSet { defaults.set(ignoredAppIdentifiers, forKey: Keys.ignoredAppIdentifiers) }
    }
    
    // MARK: - Initialization
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
        // Load saved values or use defaults
        self.syncEnabled = defaults.object(forKey: Keys.syncEnabled) as? Bool ?? true
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        
        if let themeRaw = defaults.string(forKey: Keys.theme),
           let theme = AppTheme(rawValue: themeRaw) {
            self.theme = theme
        } else {
            self.theme = .system
        }
        
        if let retentionRaw = defaults.string(forKey: Keys.historyRetention),
           let retention = HistoryRetention(rawValue: retentionRaw) {
            self.historyRetention = retention
        } else {
            self.historyRetention = .forever
        }
        
        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        self.hapticEnabled = defaults.object(forKey: Keys.hapticEnabled) as? Bool ?? true
        self.showPreviews = defaults.object(forKey: Keys.showPreviews) as? Bool ?? true
        self.autoDeleteSensitive = defaults.object(forKey: Keys.autoDeleteSensitive) as? Bool ?? true
        self.sensitiveDataDelay = defaults.object(forKey: Keys.sensitiveDataDelay) as? Int ?? 5
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        self.lastSyncDate = defaults.object(forKey: Keys.lastSyncDate) as? Date
        self.ignoredAppIdentifiers = defaults.stringArray(forKey: Keys.ignoredAppIdentifiers) ?? []
    }
    
    // MARK: - Methods
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        syncEnabled = true
        notificationsEnabled = true
        theme = .system
        historyRetention = .forever
        soundEnabled = true
        hapticEnabled = true
        showPreviews = true
        autoDeleteSensitive = true
        sensitiveDataDelay = 5
        ignoredAppIdentifiers = []
    }
    
    /// Format last sync date for display
    var formattedLastSyncDate: String {
        guard let date = lastSyncDate else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - App Group Support

extension UserSettings {
    /// UserDefaults suite for App Group sharing with extensions
    static let appGroupIdentifier = "group.adilemre.clipkeep"
    
    /// Create settings instance that shares data with extensions
    static func shared(forAppGroup: Bool) -> UserSettings {
        if forAppGroup,
           let groupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            return UserSettings(defaults: groupDefaults)
        }
        return UserSettings()
    }
}
