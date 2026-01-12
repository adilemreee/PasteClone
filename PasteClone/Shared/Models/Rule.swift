//
//  Rule.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import Foundation
import SwiftUI

/// Action to take when a rule matches
enum RuleAction: String, Codable, CaseIterable, Identifiable {
    case ignore = "ignore"
    case clear = "clear"
    case mask = "mask"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .ignore: return "Don't Save"
        case .clear: return "Clear After Delay"
        case .mask: return "Mask Content"
        }
    }
    
    var description: String {
        switch self {
        case .ignore: return "The copied content will not be saved to history"
        case .clear: return "The clipboard will be cleared after a short delay"
        case .mask: return "The content will be saved but displayed as masked"
        }
    }
    
    var icon: String {
        switch self {
        case .ignore: return "slash.circle"
        case .clear: return "xmark.circle"
        case .mask: return "eye.slash"
        }
    }
}

/// Represents a rule for handling sensitive data
struct Rule: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var pattern: String
    var action: RuleAction
    var isEnabled: Bool
    var isBuiltIn: Bool
    var description: String?
    var createdDate: Date
    var modifiedDate: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        pattern: String,
        action: RuleAction = .ignore,
        isEnabled: Bool = true,
        isBuiltIn: Bool = false,
        description: String? = nil,
        createdDate: Date = Date(),
        modifiedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.pattern = pattern
        self.action = action
        self.isEnabled = isEnabled
        self.isBuiltIn = isBuiltIn
        self.description = description
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }
    
    // MARK: - Validation
    
    /// Check if the pattern is a valid regex
    var isValidPattern: Bool {
        do {
            _ = try NSRegularExpression(pattern: pattern, options: [])
            return true
        } catch {
            return false
        }
    }
    
    /// Test if content matches this rule
    func matches(_ content: String) -> Bool {
        guard isEnabled else { return false }
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(content.startIndex..., in: content)
            return regex.firstMatch(in: content, options: [], range: range) != nil
        } catch {
            return false
        }
    }
    
    // MARK: - Mutations
    
    mutating func toggle() {
        isEnabled.toggle()
        modifiedDate = Date()
    }
    
    mutating func updatePattern(_ newPattern: String) {
        pattern = newPattern
        modifiedDate = Date()
    }
    
    mutating func updateAction(_ newAction: RuleAction) {
        action = newAction
        modifiedDate = Date()
    }
}

// MARK: - Built-in Rules

extension Rule {
    /// Built-in rules for common sensitive data patterns
    static let builtInRules: [Rule] = [
        Rule(
            name: "Passwords",
            pattern: #"(?i)(password|passwort|senha|contraseña)[\s:=]+.+"#,
            action: .ignore,
            isBuiltIn: true,
            description: "Detects text that appears to contain passwords"
        ),
        Rule(
            name: "Credit Cards",
            pattern: #"\b(?:\d{4}[\s-]?){3}\d{4}\b"#,
            action: .ignore,
            isBuiltIn: true,
            description: "Detects credit card number patterns"
        ),
        Rule(
            name: "One-Time Codes",
            pattern: #"\b\d{4,8}\b"#,
            action: .clear,
            isEnabled: false, // Disabled by default as it may be too aggressive
            isBuiltIn: true,
            description: "Detects numeric verification codes"
        ),
        Rule(
            name: "API Keys",
            pattern: #"(?i)(api[_-]?key|apikey|secret[_-]?key)[\s:=]+[a-zA-Z0-9_-]+"#,
            action: .ignore,
            isBuiltIn: true,
            description: "Detects API keys and secrets"
        ),
        Rule(
            name: "Email Addresses",
            pattern: #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#,
            action: .mask,
            isEnabled: false, // Disabled by default
            isBuiltIn: true,
            description: "Detects email addresses"
        ),
        Rule(
            name: "Social Security Numbers",
            pattern: #"\b\d{3}-\d{2}-\d{4}\b"#,
            action: .ignore,
            isBuiltIn: true,
            description: "Detects US Social Security Number patterns"
        ),
        Rule(
            name: "Bearer Tokens",
            pattern: #"(?i)bearer\s+[a-zA-Z0-9._-]+"#,
            action: .ignore,
            isBuiltIn: true,
            description: "Detects Bearer authentication tokens"
        ),
        Rule(
            name: "Private Keys",
            pattern: #"(?i)-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----"#,
            action: .ignore,
            isBuiltIn: true,
            description: "Detects private key headers"
        )
    ]
    
    /// Sample custom rule for previews
    static let sampleCustom = Rule(
        name: "Bank Account",
        pattern: #"\b\d{10,12}\b"#,
        action: .mask,
        description: "Masks bank account numbers"
    )
}

// MARK: - Rule Manager

@Observable
final class RuleManager {
    static let shared = RuleManager()
    
    private let defaults: UserDefaults
    private let rulesKey = "savedRules"
    
    /// All rules including built-in and custom
    var rules: [Rule] {
        didSet { saveRules() }
    }
    
    /// Only enabled rules
    var enabledRules: [Rule] {
        rules.filter { $0.isEnabled }
    }
    
    /// Only custom (non-built-in) rules
    var customRules: [Rule] {
        rules.filter { !$0.isBuiltIn }
    }
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
        // Load saved rules or use defaults
        if let data = defaults.data(forKey: rulesKey),
           let savedRules = try? JSONDecoder().decode([Rule].self, from: data) {
            self.rules = savedRules
        } else {
            self.rules = Rule.builtInRules
        }
    }
    
    private func saveRules() {
        if let data = try? JSONEncoder().encode(rules) {
            defaults.set(data, forKey: rulesKey)
        }
    }
    
    /// Add a new custom rule
    func addRule(_ rule: Rule) {
        rules.append(rule)
    }
    
    /// Remove a rule by ID
    func removeRule(id: UUID) {
        rules.removeAll { $0.id == id }
    }
    
    /// Update an existing rule
    func updateRule(_ rule: Rule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        }
    }
    
    /// Toggle a rule's enabled state
    func toggleRule(id: UUID) {
        if let index = rules.firstIndex(where: { $0.id == id }) {
            rules[index].toggle()
        }
    }
    
    /// Check content against all enabled rules
    func check(_ content: String) -> (matches: Bool, action: RuleAction?) {
        for rule in enabledRules {
            if rule.matches(content) {
                return (true, rule.action)
            }
        }
        return (false, nil)
    }
    
    /// Reset to built-in rules only
    func resetToDefaults() {
        rules = Rule.builtInRules
    }
}
