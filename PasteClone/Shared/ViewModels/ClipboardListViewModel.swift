//
//  ClipboardListViewModel.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import Foundation
import SwiftUI
import UIKit

/// View model for the clipboard history list
@Observable
@MainActor
final class ClipboardListViewModel {
    // MARK: - Properties
    
    /// All clipboard items grouped by date
    private(set) var groupedItems: [(date: Date, items: [ClipboardItem])] = []
    
    /// Recent items (flat list)
    private(set) var recentItems: [ClipboardItem] = []
    
    /// Currently selected items (for multi-select)
    var selectedItems: Set<UUID> = []
    
    /// Whether multi-select mode is active
    var isMultiSelectMode = false
    
    /// Loading state
    private(set) var isLoading = false
    
    /// Error message if any
    private(set) var errorMessage: String?
    
    /// Storage manager reference
    private let storageManager: StorageManager
    
    /// Clipboard monitor reference
    private let clipboardMonitor: ClipboardMonitor
    
    // MARK: - Initialization
    
    init(
        storageManager: StorageManager = .shared,
        clipboardMonitor: ClipboardMonitor = .shared
    ) {
        self.storageManager = storageManager
        self.clipboardMonitor = clipboardMonitor
        
        loadItems()
        setupMonitor()
    }
    
    // MARK: - Public Methods
    
    /// Refresh items from storage
    func refresh() {
        loadItems()
    }
    
    /// Copy item to clipboard
    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = UIPasteboard.general
        
        switch item.type {
        case .text:
            pasteboard.string = item.rawData
        case .link:
            if let url = URL(string: item.rawData) {
                pasteboard.url = url
            } else {
                pasteboard.string = item.rawData
            }
        case .image:
            if let data = Data(base64Encoded: item.rawData),
               let image = UIImage(data: data) {
                pasteboard.image = image
            }
        case .file:
            if let url = URL(string: item.rawData) {
                pasteboard.url = url
            }
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Delete an item
    func delete(_ item: ClipboardItem) {
        storageManager.delete(item)
        loadItems()
    }
    
    /// Delete multiple items
    func deleteSelected() {
        guard !selectedItems.isEmpty else { return }
        storageManager.delete(selectedItems)
        selectedItems.removeAll()
        isMultiSelectMode = false
        loadItems()
    }
    
    /// Pin item to a pinboard
    func pin(_ item: ClipboardItem, to pinboard: Pinboard) {
        storageManager.addItemToPinboard(item.id, pinboardId: pinboard.id)
        loadItems()
    }
    
    /// Unpin item from a pinboard
    func unpin(_ item: ClipboardItem, from pinboard: Pinboard) {
        storageManager.removeItemFromPinboard(item.id, pinboardId: pinboard.id)
        loadItems()
    }
    
    /// Share item
    func shareItem(_ item: ClipboardItem) -> [Any] {
        var items: [Any] = []
        
        switch item.type {
        case .text:
            items.append(item.rawData)
        case .link:
            if let url = URL(string: item.rawData) {
                items.append(url)
            }
        case .image:
            if let data = Data(base64Encoded: item.rawData),
               let image = UIImage(data: data) {
                items.append(image)
            }
        case .file:
            if let url = URL(string: item.rawData) {
                items.append(url)
            }
        }
        
        return items
    }
    
    /// Toggle selection for multi-select
    func toggleSelection(_ item: ClipboardItem) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
        
        // Exit multi-select if nothing selected
        if selectedItems.isEmpty {
            isMultiSelectMode = false
        }
    }
    
    /// Select all items
    func selectAll() {
        selectedItems = Set(storageManager.items.map { $0.id })
        isMultiSelectMode = true
    }
    
    /// Clear selection
    func clearSelection() {
        selectedItems.removeAll()
        isMultiSelectMode = false
    }
    
    /// Clear all history
    func clearAllHistory() {
        storageManager.clearAllHistory()
        loadItems()
    }
    
    // MARK: - Private Methods
    
    private func loadItems() {
        isLoading = true
        
        // Get all items
        let allItems = storageManager.items
        
        // Update recent items
        recentItems = Array(allItems.prefix(50))
        
        // Group by date
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allItems) { item in
            calendar.startOfDay(for: item.timestamp)
        }
        
        // Sort groups by date (newest first)
        groupedItems = grouped
            .map { (date: $0.key, items: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.date > $1.date }
        
        isLoading = false
    }
    
    private func setupMonitor() {
        // Listen for new items
        clipboardMonitor.onNewItem = { [weak self] _ in
            Task { @MainActor in
                self?.loadItems()
            }
        }
    }
}

// MARK: - Computed Properties

extension ClipboardListViewModel {
    /// Total item count
    var itemCount: Int {
        storageManager.items.count
    }
    
    /// Items copied today
    var todayCount: Int {
        storageManager.todayItems().count
    }
    
    /// Available pinboards for pinning
    var availablePinboards: [Pinboard] {
        storageManager.pinboards
    }
    
    /// Check if item is selected
    func isSelected(_ item: ClipboardItem) -> Bool {
        selectedItems.contains(item.id)
    }
    
    /// Get section title for date
    func sectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}
