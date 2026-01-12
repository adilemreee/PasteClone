//
//  KeyboardDataProvider.swift
//  ClipboardKeyboard
//
//  Created for ClipKeep - Clipboard Manager Keyboard Extension
//

import Foundation
import SwiftUI

/// Provides clipboard data to the keyboard extension via App Group shared storage
@Observable
@MainActor
final class KeyboardDataProvider {
    // MARK: - Properties
    
    /// Recent clipboard items
    private(set) var recentItems: [ClipboardItem] = []
    
    /// Available pinboards
    private(set) var pinboards: [Pinboard] = []
    
    /// All items (for looking up pinboard contents)
    private(set) var allItems: [ClipboardItem] = []
    
    /// Whether data is loading
    private(set) var isLoading = false
    
    /// Error message if any
    private(set) var errorMessage: String?
    
    /// UserDefaults for App Group
    private let defaults: UserDefaults?
    
    /// App Group identifier
    private static let appGroupIdentifier = "group.adilemre.clipkeep"
    
    /// Storage keys
    private enum Keys {
        static let clipboardItems = "clipboardItems"
        static let pinboards = "pinboards"
    }
    
    /// Maximum items to show in keyboard
    private let maxRecentItems = 20
    
    // MARK: - Initialization
    
    init() {
        self.defaults = UserDefaults(suiteName: Self.appGroupIdentifier)
        refresh()
    }
    
    // MARK: - Public Methods
    
    /// Refresh data from shared storage
    func refresh() {
        isLoading = true
        errorMessage = nil
        
        loadItems()
        loadPinboards()
        
        isLoading = false
    }
    
    /// Get items for a specific pinboard
    func items(for pinboard: Pinboard) -> [ClipboardItem] {
        pinboard.itemIds.compactMap { itemId in
            allItems.first { $0.id == itemId }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadItems() {
        guard let defaults = defaults,
              let data = defaults.data(forKey: Keys.clipboardItems),
              let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) else {
            recentItems = []
            allItems = []
            return
        }
        
        // Sort by timestamp, newest first
        let sorted = items.sorted { $0.timestamp > $1.timestamp }
        
        // Store all items for pinboard lookup
        allItems = sorted
        
        // Only recent items for display
        recentItems = Array(sorted.prefix(maxRecentItems))
    }
    
    private func loadPinboards() {
        guard let defaults = defaults,
              let data = defaults.data(forKey: Keys.pinboards),
              let boards = try? JSONDecoder().decode([Pinboard].self, from: data) else {
            pinboards = []
            return
        }
        
        // Sort by sort order
        pinboards = boards.sorted { $0.sortOrder < $1.sortOrder }
    }
}

// MARK: - Preview Support

extension KeyboardDataProvider {
    /// Create a provider with sample data for previews
    static func preview() -> KeyboardDataProvider {
        let provider = KeyboardDataProvider()
        provider.recentItems = ClipboardItem.sampleItems
        provider.allItems = ClipboardItem.sampleItems
        provider.pinboards = Pinboard.samplePinboards
        return provider
    }
}
