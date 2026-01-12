//
//  StorageManager.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import Foundation
import SwiftUI

/// Manages persistent storage for clipboard items and pinboards
/// Uses UserDefaults initially with App Group sharing for extensions
/// Note: Core Data + CloudKit integration can be added for production
@Observable
@MainActor
final class StorageManager {
    // MARK: - Singleton
    
    static let shared = StorageManager()
    
    // MARK: - Storage Keys
    
    private enum Keys {
        static let clipboardItems = "clipboardItems"
        static let pinboards = "pinboards"
        static let lastCleanupDate = "lastCleanupDate"
    }
    
    // MARK: - Properties
    
    /// All clipboard items
    private(set) var items: [ClipboardItem] = []
    
    /// All pinboards
    private(set) var pinboards: [Pinboard] = []
    
    /// UserDefaults for persistence
    private let defaults: UserDefaults
    
    /// App Group identifier for sharing with extensions
    static let appGroupIdentifier = "group.adilemre.clipkeep"
    
    /// Maximum number of items to keep (for performance)
    private let maxItems = 10000
    
    // MARK: - Initialization
    
    init(defaults: UserDefaults? = nil) {
        // Use App Group defaults if available, otherwise standard
        if let groupDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) {
            self.defaults = defaults ?? groupDefaults
        } else {
            self.defaults = defaults ?? .standard
        }
        
        loadItems()
        loadPinboards()
        performCleanupIfNeeded()
    }
    
    // MARK: - Clipboard Items
    
    /// Load items from storage
    private func loadItems() {
        guard let data = defaults.data(forKey: Keys.clipboardItems),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) else {
            items = []
            return
        }
        items = decoded.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Save items to storage
    private func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: Keys.clipboardItems)
        }
    }
    
    /// Add a new clipboard item
    func save(_ item: ClipboardItem) {
        // Check for duplicate content
        if let existingIndex = items.firstIndex(where: { $0.rawData == item.rawData }) {
            // Move existing item to top instead of adding duplicate
            var existingItem = items.remove(at: existingIndex)
            existingItem = ClipboardItem(
                id: existingItem.id,
                timestamp: Date(),
                type: existingItem.type,
                rawData: existingItem.rawData,
                previewText: existingItem.previewText,
                sourceAppIdentifier: item.sourceAppIdentifier ?? existingItem.sourceAppIdentifier,
                tags: existingItem.tags,
                linkTitle: existingItem.linkTitle,
                faviconURL: existingItem.faviconURL,
                fileName: existingItem.fileName,
                thumbnailData: existingItem.thumbnailData,
                isPinned: existingItem.isPinned,
                pinboardIds: existingItem.pinboardIds
            )
            items.insert(existingItem, at: 0)
        } else {
            items.insert(item, at: 0)
        }
        
        // Trim if over limit
        if items.count > maxItems {
            // Keep pinned items, remove oldest non-pinned
            let pinnedItems = items.filter { $0.isPinned }
            let nonPinnedItems = items.filter { !$0.isPinned }
            items = pinnedItems + Array(nonPinnedItems.prefix(maxItems - pinnedItems.count))
        }
        
        saveItems()
    }
    
    /// Delete a clipboard item
    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        
        // Also remove from pinboards
        for i in pinboards.indices {
            pinboards[i].removeItem(item.id)
        }
        
        saveItems()
        savePinboards()
    }
    
    /// Delete multiple items
    func delete(_ itemIds: Set<UUID>) {
        items.removeAll { itemIds.contains($0.id) }
        
        for i in pinboards.indices {
            for id in itemIds {
                pinboards[i].removeItem(id)
            }
        }
        
        saveItems()
        savePinboards()
    }
    
    /// Update an existing item
    func update(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveItems()
        }
    }
    
    /// Get item by ID
    func item(withId id: UUID) -> ClipboardItem? {
        items.first { $0.id == id }
    }
    
    /// Get items for a specific type
    func items(ofType type: ClipboardItemType) -> [ClipboardItem] {
        items.filter { $0.type == type }
    }
    
    /// Get items for today
    func todayItems() -> [ClipboardItem] {
        let calendar = Calendar.current
        return items.filter { calendar.isDateInToday($0.timestamp) }
    }
    
    /// Get recent items (limited count)
    func recentItems(limit: Int = 50) -> [ClipboardItem] {
        Array(items.prefix(limit))
    }
    
    /// Clear all history
    func clearAllHistory() {
        // Keep only pinned items
        items = items.filter { $0.isPinned }
        saveItems()
    }
    
    // MARK: - Pinboards
    
    /// Load pinboards from storage
    private func loadPinboards() {
        guard let data = defaults.data(forKey: Keys.pinboards),
              let decoded = try? JSONDecoder().decode([Pinboard].self, from: data) else {
            pinboards = []
            return
        }
        pinboards = decoded.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    /// Save pinboards to storage
    private func savePinboards() {
        if let data = try? JSONEncoder().encode(pinboards) {
            defaults.set(data, forKey: Keys.pinboards)
        }
    }
    
    /// Create a new pinboard
    func createPinboard(name: String, icon: String = "pin.fill", color: String = "blue") -> Pinboard {
        let pinboard = Pinboard(
            name: name,
            iconName: icon,
            color: color,
            sortOrder: pinboards.count
        )
        pinboards.append(pinboard)
        savePinboards()
        return pinboard
    }
    
    /// Delete a pinboard
    func deletePinboard(_ pinboard: Pinboard) {
        // Remove pinboard reference from all items
        for i in items.indices {
            items[i].pinboardIds.removeAll { $0 == pinboard.id }
            if items[i].pinboardIds.isEmpty {
                items[i].isPinned = false
            }
        }
        
        pinboards.removeAll { $0.id == pinboard.id }
        saveItems()
        savePinboards()
    }
    
    /// Update a pinboard
    func updatePinboard(_ pinboard: Pinboard) {
        if let index = pinboards.firstIndex(where: { $0.id == pinboard.id }) {
            pinboards[index] = pinboard
            savePinboards()
        }
    }
    
    /// Add item to pinboard
    func addItemToPinboard(_ itemId: UUID, pinboardId: UUID) {
        // Update pinboard
        if let pbIndex = pinboards.firstIndex(where: { $0.id == pinboardId }) {
            pinboards[pbIndex].addItem(itemId)
        }
        
        // Update item
        if let itemIndex = items.firstIndex(where: { $0.id == itemId }) {
            items[itemIndex].isPinned = true
            if !items[itemIndex].pinboardIds.contains(pinboardId) {
                items[itemIndex].pinboardIds.append(pinboardId)
            }
        }
        
        saveItems()
        savePinboards()
    }
    
    /// Remove item from pinboard
    func removeItemFromPinboard(_ itemId: UUID, pinboardId: UUID) {
        // Update pinboard
        if let pbIndex = pinboards.firstIndex(where: { $0.id == pinboardId }) {
            pinboards[pbIndex].removeItem(itemId)
        }
        
        // Update item
        if let itemIndex = items.firstIndex(where: { $0.id == itemId }) {
            items[itemIndex].pinboardIds.removeAll { $0 == pinboardId }
            if items[itemIndex].pinboardIds.isEmpty {
                items[itemIndex].isPinned = false
            }
        }
        
        saveItems()
        savePinboards()
    }
    
    /// Get items for a specific pinboard
    func items(forPinboard pinboard: Pinboard) -> [ClipboardItem] {
        pinboard.itemIds.compactMap { itemId in
            items.first { $0.id == itemId }
        }
    }
    
    /// Reorder pinboards
    func reorderPinboards(_ newOrder: [Pinboard]) {
        pinboards = newOrder.enumerated().map { index, pinboard in
            var updated = pinboard
            updated.sortOrder = index
            return updated
        }
        savePinboards()
    }
    
    // MARK: - Cleanup
    
    /// Perform cleanup based on retention settings
    private func performCleanupIfNeeded() {
        let lastCleanup = defaults.object(forKey: Keys.lastCleanupDate) as? Date ?? .distantPast
        let calendar = Calendar.current
        
        // Only cleanup once per day
        guard !calendar.isDateInToday(lastCleanup) else { return }
        
        let settings = UserSettings.shared
        guard let retentionDays = settings.historyRetention.days else { return }
        
        let cutoffDate = calendar.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        
        // Remove old non-pinned items
        let beforeCount = items.count
        items.removeAll { !$0.isPinned && $0.timestamp < cutoffDate }
        
        if items.count != beforeCount {
            saveItems()
            print("🧹 StorageManager: Cleaned up \(beforeCount - items.count) old items")
        }
        
        defaults.set(Date(), forKey: Keys.lastCleanupDate)
    }
}

// MARK: - Search Support

extension StorageManager {
    /// Search items with query and optional filters
    func search(
        query: String,
        types: Set<ClipboardItemType>? = nil,
        dateRange: ClosedRange<Date>? = nil
    ) -> [ClipboardItem] {
        var results = items
        
        // Filter by query
        if !query.isEmpty {
            let lowercasedQuery = query.lowercased()
            results = results.filter { item in
                item.previewText?.lowercased().contains(lowercasedQuery) == true ||
                item.rawData.lowercased().contains(lowercasedQuery) ||
                item.tags.contains { $0.lowercased().contains(lowercasedQuery) }
            }
        }
        
        // Filter by types
        if let types = types, !types.isEmpty {
            results = results.filter { types.contains($0.type) }
        }
        
        // Filter by date range
        if let dateRange = dateRange {
            results = results.filter { dateRange.contains($0.timestamp) }
        }
        
        return results
    }
}
