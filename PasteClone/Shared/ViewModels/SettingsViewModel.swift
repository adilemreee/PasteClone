//
//  SettingsViewModel.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import Foundation
import SwiftUI

/// View model for settings management
@Observable
@MainActor
final class SettingsViewModel {
    // MARK: - Properties
    
    /// User settings reference
    private let settings: UserSettings
    
    /// Rule manager reference
    private let ruleManager: RuleManager
    
    /// Sync manager reference
    private let syncManager: SyncManager
    
    /// Storage manager reference
    private let storageManager: StorageManager
    
    // MARK: - Settings Bindings
    
    var syncEnabled: Bool {
        get { settings.syncEnabled }
        set { settings.syncEnabled = newValue }
    }
    
    var notificationsEnabled: Bool {
        get { settings.notificationsEnabled }
        set { settings.notificationsEnabled = newValue }
    }
    
    var theme: AppTheme {
        get { settings.theme }
        set { settings.theme = newValue }
    }
    
    var historyRetention: HistoryRetention {
        get { settings.historyRetention }
        set { settings.historyRetention = newValue }
    }
    
    var soundEnabled: Bool {
        get { settings.soundEnabled }
        set { settings.soundEnabled = newValue }
    }
    
    var hapticEnabled: Bool {
        get { settings.hapticEnabled }
        set { settings.hapticEnabled = newValue }
    }
    
    var showPreviews: Bool {
        get { settings.showPreviews }
        set { settings.showPreviews = newValue }
    }
    
    var autoDeleteSensitive: Bool {
        get { settings.autoDeleteSensitive }
        set { settings.autoDeleteSensitive = newValue }
    }
    
    var sensitiveDataDelay: Int {
        get { settings.sensitiveDataDelay }
        set { settings.sensitiveDataDelay = newValue }
    }
    
    // MARK: - Rules
    
    var rules: [Rule] {
        ruleManager.rules
    }
    
    var customRules: [Rule] {
        ruleManager.customRules
    }
    
    var builtInRules: [Rule] {
        ruleManager.rules.filter { $0.isBuiltIn }
    }
    
    // MARK: - Stats
    
    var totalItemCount: Int {
        storageManager.items.count
    }
    
    var totalPinboardCount: Int {
        storageManager.pinboards.count
    }
    
    var lastSyncDate: Date? {
        settings.lastSyncDate
    }
    
    var formattedLastSync: String {
        settings.formattedLastSyncDate
    }
    
    var syncStatus: SyncManager.SyncStatus {
        syncManager.status
    }
    
    // MARK: - Initialization
    
    init(
        settings: UserSettings = .shared,
        ruleManager: RuleManager = .shared,
        syncManager: SyncManager = .shared,
        storageManager: StorageManager = .shared
    ) {
        self.settings = settings
        self.ruleManager = ruleManager
        self.syncManager = syncManager
        self.storageManager = storageManager
    }
    
    // MARK: - Public Methods
    
    /// Reset all settings to defaults
    func resetSettings() {
        settings.resetToDefaults()
    }
    
    /// Trigger manual sync
    func triggerSync() async {
        await syncManager.sync()
    }
    
    /// Clear all clipboard history
    func clearHistory() {
        storageManager.clearAllHistory()
    }
    
    // MARK: - Rule Management
    
    /// Add a new rule
    func addRule(name: String, pattern: String, action: RuleAction) {
        let rule = Rule(
            name: name,
            pattern: pattern,
            action: action
        )
        ruleManager.addRule(rule)
    }
    
    /// Update an existing rule
    func updateRule(_ rule: Rule) {
        ruleManager.updateRule(rule)
    }
    
    /// Delete a rule
    func deleteRule(_ rule: Rule) {
        ruleManager.removeRule(id: rule.id)
    }
    
    /// Toggle rule enabled state
    func toggleRule(_ rule: Rule) {
        ruleManager.toggleRule(id: rule.id)
    }
    
    /// Reset rules to defaults
    func resetRules() {
        ruleManager.resetToDefaults()
    }
    
    /// Validate a regex pattern
    func validatePattern(_ pattern: String) -> Bool {
        do {
            _ = try NSRegularExpression(pattern: pattern, options: [])
            return true
        } catch {
            return false
        }
    }
    
    /// Test pattern against sample text
    func testPattern(_ pattern: String, against text: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(text.startIndex..., in: text)
            return regex.firstMatch(in: text, options: [], range: range) != nil
        } catch {
            return false
        }
    }
}

// MARK: - App Info

extension SettingsViewModel {
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var fullVersion: String {
        "\(appVersion) (\(buildNumber))"
    }
}

// MARK: - Export/Import

extension SettingsViewModel {
    /// Export settings and rules as JSON
    func exportSettings() -> Data? {
        let export = SettingsExport(
            settings: SettingsData(
                syncEnabled: syncEnabled,
                notificationsEnabled: notificationsEnabled,
                theme: theme.rawValue,
                historyRetention: historyRetention.rawValue,
                soundEnabled: soundEnabled,
                hapticEnabled: hapticEnabled,
                showPreviews: showPreviews,
                autoDeleteSensitive: autoDeleteSensitive,
                sensitiveDataDelay: sensitiveDataDelay
            ),
            customRules: customRules
        )
        
        return try? JSONEncoder().encode(export)
    }
    
    /// Import settings and rules from JSON
    func importSettings(from data: Data) throws {
        let export = try JSONDecoder().decode(SettingsExport.self, from: data)
        
        // Apply settings
        syncEnabled = export.settings.syncEnabled
        notificationsEnabled = export.settings.notificationsEnabled
        if let theme = AppTheme(rawValue: export.settings.theme) {
            self.theme = theme
        }
        if let retention = HistoryRetention(rawValue: export.settings.historyRetention) {
            historyRetention = retention
        }
        soundEnabled = export.settings.soundEnabled
        hapticEnabled = export.settings.hapticEnabled
        showPreviews = export.settings.showPreviews
        autoDeleteSensitive = export.settings.autoDeleteSensitive
        sensitiveDataDelay = export.settings.sensitiveDataDelay
        
        // Import custom rules
        for rule in export.customRules {
            ruleManager.addRule(rule)
        }
    }
}

// MARK: - Export Structures

private struct SettingsExport: Codable {
    let settings: SettingsData
    let customRules: [Rule]
}

private struct SettingsData: Codable {
    let syncEnabled: Bool
    let notificationsEnabled: Bool
    let theme: String
    let historyRetention: String
    let soundEnabled: Bool
    let hapticEnabled: Bool
    let showPreviews: Bool
    let autoDeleteSensitive: Bool
    let sensitiveDataDelay: Int
}
