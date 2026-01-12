//
//  SecurityManager.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import Foundation

/// Manages sensitive data detection and handling
@Observable
@MainActor
final class SecurityManager {
    // MARK: - Singleton
    
    static let shared = SecurityManager()
    
    // MARK: - Properties
    
    /// Rule manager for user-defined rules
    private let ruleManager: RuleManager
    
    /// Settings for security preferences
    private let settings: UserSettings
    
    /// Cache of recently checked content hashes
    private var checkedCache: [Int: (matches: Bool, action: RuleAction?)] = [:]
    
    /// Maximum cache size
    private let maxCacheSize = 500
    
    // MARK: - Initialization
    
    init(ruleManager: RuleManager = .shared, settings: UserSettings = .shared) {
        self.ruleManager = ruleManager
        self.settings = settings
    }
    
    // MARK: - Public Methods
    
    /// Check if content should be ignored (not saved)
    func shouldIgnore(_ content: String) -> Bool {
        let result = checkContent(content)
        return result.matches && (result.action == .ignore || result.action == .clear)
    }
    
    /// Check if content should be cleared from clipboard
    func shouldClear(_ content: String) -> Bool {
        let result = checkContent(content)
        return result.matches && result.action == .clear
    }
    
    /// Check if content should be masked in display
    func shouldMask(_ content: String) -> Bool {
        let result = checkContent(content)
        return result.matches && result.action == .mask
    }
    
    /// Get the action for content if any rule matches
    func getAction(for content: String) -> RuleAction? {
        let result = checkContent(content)
        return result.matches ? result.action : nil
    }
    
    /// Check content against all rules
    func checkContent(_ content: String) -> (matches: Bool, action: RuleAction?) {
        // Check cache first
        let hash = content.hashValue
        if let cached = checkedCache[hash] {
            return cached
        }
        
        // Check against rules
        let result = ruleManager.check(content)
        
        // Cache result
        if checkedCache.count >= maxCacheSize {
            // Remove oldest entries (simple approach: clear half)
            let keysToRemove = Array(checkedCache.keys.prefix(maxCacheSize / 2))
            for key in keysToRemove {
                checkedCache.removeValue(forKey: key)
            }
        }
        checkedCache[hash] = result
        
        return result
    }
    
    /// Mask sensitive content for display
    func maskContent(_ content: String) -> String {
        guard shouldMask(content) else { return content }
        
        // Apply masking to detected patterns
        var masked = content
        
        for rule in ruleManager.enabledRules where rule.action == .mask {
            if let regex = try? NSRegularExpression(pattern: rule.pattern, options: [.caseInsensitive]) {
                let range = NSRange(masked.startIndex..., in: masked)
                masked = regex.stringByReplacingMatches(
                    in: masked,
                    options: [],
                    range: range,
                    withTemplate: "••••••••"
                )
            }
        }
        
        return masked
    }
    
    /// Clear the check cache
    func clearCache() {
        checkedCache.removeAll()
    }
    
    // MARK: - Quick Checks
    
    /// Check if content looks like a password
    func looksLikePassword(_ content: String) -> Bool {
        let passwordPatterns = [
            #"(?i)password[\s:=]+"#,
            #"(?i)passwort[\s:=]+"#,
            #"(?i)contraseña[\s:=]+"#,
            #"(?i)senha[\s:=]+"#
        ]
        
        for pattern in passwordPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)) != nil {
                return true
            }
        }
        
        return false
    }
    
    /// Check if content looks like a credit card
    func looksLikeCreditCard(_ content: String) -> Bool {
        let pattern = #"\b(?:\d{4}[\s-]?){3}\d{4}\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return false }
        return regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)) != nil
    }
    
    /// Check if content looks like an API key
    func looksLikeAPIKey(_ content: String) -> Bool {
        let patterns = [
            #"(?i)api[_-]?key[\s:=]+"#,
            #"(?i)secret[_-]?key[\s:=]+"#,
            #"(?i)access[_-]?token[\s:=]+"#,
            #"(?i)bearer\s+"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)) != nil {
                return true
            }
        }
        
        return false
    }
    
    /// Get security analysis of content
    func analyzeContent(_ content: String) -> SecurityAnalysis {
        var warnings: [String] = []
        var suggestions: [String] = []
        
        if looksLikePassword(content) {
            warnings.append("Content appears to contain a password")
            suggestions.append("Consider enabling the 'Passwords' rule to auto-ignore")
        }
        
        if looksLikeCreditCard(content) {
            warnings.append("Content appears to contain a credit card number")
            suggestions.append("Consider enabling the 'Credit Cards' rule to auto-ignore")
        }
        
        if looksLikeAPIKey(content) {
            warnings.append("Content appears to contain an API key or token")
            suggestions.append("Consider enabling the 'API Keys' rule to auto-ignore")
        }
        
        let action = getAction(for: content)
        
        return SecurityAnalysis(
            isSensitive: !warnings.isEmpty,
            warnings: warnings,
            suggestions: suggestions,
            matchedAction: action
        )
    }
}

// MARK: - Security Analysis Result

struct SecurityAnalysis {
    let isSensitive: Bool
    let warnings: [String]
    let suggestions: [String]
    let matchedAction: RuleAction?
    
    var riskLevel: RiskLevel {
        if matchedAction == .ignore || matchedAction == .clear {
            return .high
        } else if matchedAction == .mask {
            return .medium
        } else if isSensitive {
            return .medium
        }
        return .low
    }
    
    enum RiskLevel: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }
}
