//
//  PinboardViewModel.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import Foundation
import SwiftUI
import CloudKit

/// View model for pinboard management
@Observable
@MainActor
final class PinboardViewModel {
    // MARK: - Properties
    
    /// All pinboards
    private(set) var pinboards: [Pinboard] = []
    
    /// Currently selected pinboard
    var selectedPinboard: Pinboard?
    
    /// Items in the selected pinboard
    private(set) var selectedPinboardItems: [ClipboardItem] = []
    
    /// Shared pinboards from other users
    private(set) var sharedPinboards: [Pinboard] = []
    
    /// Loading state
    private(set) var isLoading = false
    
    /// Error message
    private(set) var errorMessage: String?
    
    /// Storage manager reference
    private let storageManager: StorageManager
    
    /// Sync manager for sharing
    private let syncManager: SyncManager
    
    // MARK: - Initialization
    
    init(
        storageManager: StorageManager = .shared,
        syncManager: SyncManager = .shared
    ) {
        self.storageManager = storageManager
        self.syncManager = syncManager
        
        loadPinboards()
    }
    
    // MARK: - Public Methods
    
    /// Refresh pinboards from storage
    func refresh() {
        loadPinboards()
    }
    
    /// Create a new pinboard
    func createPinboard(name: String, icon: String = "pin.fill", color: String = "blue") {
        let _ = storageManager.createPinboard(name: name, icon: icon, color: color)
        loadPinboards()
    }
    
    /// Delete a pinboard
    func deletePinboard(_ pinboard: Pinboard) {
        if selectedPinboard?.id == pinboard.id {
            selectedPinboard = nil
            selectedPinboardItems = []
        }
        
        storageManager.deletePinboard(pinboard)
        loadPinboards()
    }
    
    /// Rename a pinboard
    func renamePinboard(_ pinboard: Pinboard, to newName: String) {
        var updated = pinboard
        updated.rename(to: newName)
        storageManager.updatePinboard(updated)
        loadPinboards()
    }
    
    /// Update pinboard icon
    func updateIcon(_ pinboard: Pinboard, icon: String) {
        var updated = pinboard
        updated.setIcon(icon)
        storageManager.updatePinboard(updated)
        loadPinboards()
    }
    
    /// Update pinboard color
    func updateColor(_ pinboard: Pinboard, color: String) {
        var updated = pinboard
        updated.setColor(color)
        storageManager.updatePinboard(updated)
        loadPinboards()
    }
    
    /// Update pinboard with multiple properties at once
    func updatePinboard(id: UUID, name: String, icon: String, color: String) {
        guard var pinboard = pinboards.first(where: { $0.id == id }) else { return }
        pinboard.name = name
        pinboard.iconName = icon
        pinboard.color = color
        storageManager.updatePinboard(pinboard)
        loadPinboards()
    }
    
    /// Select a pinboard and load its items
    func selectPinboard(_ pinboard: Pinboard) {
        selectedPinboard = pinboard
        loadSelectedPinboardItems()
    }
    
    /// Deselect pinboard
    func deselectPinboard() {
        selectedPinboard = nil
        selectedPinboardItems = []
    }
    
    /// Add item to pinboard
    func addItem(_ item: ClipboardItem, to pinboard: Pinboard) {
        storageManager.addItemToPinboard(item.id, pinboardId: pinboard.id)
        
        if selectedPinboard?.id == pinboard.id {
            loadSelectedPinboardItems()
        }
        
        loadPinboards()
    }
    
    /// Remove item from pinboard
    func removeItem(_ item: ClipboardItem, from pinboard: Pinboard) {
        storageManager.removeItemFromPinboard(item.id, pinboardId: pinboard.id)
        
        if selectedPinboard?.id == pinboard.id {
            loadSelectedPinboardItems()
        }
        
        loadPinboards()
    }
    
    /// Reorder pinboards
    func reorderPinboards(_ newOrder: [Pinboard]) {
        storageManager.reorderPinboards(newOrder)
        loadPinboards()
    }
    
    /// Reorder items within a pinboard
    func reorderItems(_ newOrder: [ClipboardItem], in pinboard: Pinboard) {
        var updated = pinboard
        updated.reorderItems(newOrder.map { $0.id })
        storageManager.updatePinboard(updated)
        
        if selectedPinboard?.id == pinboard.id {
            selectedPinboard = updated
            loadSelectedPinboardItems()
        }
        
        loadPinboards()
    }
    
    /// Share a pinboard via CloudKit
    func sharePinboard(_ pinboard: Pinboard) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let share = try await syncManager.sharePinboard(pinboard)
            
            // Update pinboard with share URL
            var updated = pinboard
            updated.shareStatus = .shared
            updated.cloudKitShareURL = share.url?.absoluteString
            storageManager.updatePinboard(updated)
            
            loadPinboards()
        } catch {
            errorMessage = "Failed to share pinboard: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Stop sharing a pinboard
    func stopSharing(_ pinboard: Pinboard) {
        var updated = pinboard
        updated.shareStatus = .private
        updated.cloudKitShareURL = nil
        updated.sharedWithUserIds = []
        storageManager.updatePinboard(updated)
        loadPinboards()
    }
    
    /// Fetch shared pinboards from other users
    func fetchSharedPinboards() async {
        isLoading = true
        
        do {
            sharedPinboards = try await syncManager.fetchSharedPinboards()
        } catch {
            errorMessage = "Failed to fetch shared pinboards: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func loadPinboards() {
        pinboards = storageManager.pinboards
        
        // Reload selected pinboard if it still exists
        if let selected = selectedPinboard,
           let updated = pinboards.first(where: { $0.id == selected.id }) {
            selectedPinboard = updated
        }
    }
    
    private func loadSelectedPinboardItems() {
        guard let pinboard = selectedPinboard else {
            selectedPinboardItems = []
            return
        }
        
        selectedPinboardItems = storageManager.items(forPinboard: pinboard)
    }
}

// MARK: - Computed Properties

extension PinboardViewModel {
    /// Total pinboard count
    var pinboardCount: Int {
        pinboards.count
    }
    
    /// Has shared pinboards
    var hasSharedPinboards: Bool {
        pinboards.contains { $0.isShared } || !sharedPinboards.isEmpty
    }
    
    /// Pinboards sorted by name
    var pinboardsSortedByName: [Pinboard] {
        pinboards.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    /// Pinboards sorted by item count
    var pinboardsSortedByItemCount: [Pinboard] {
        pinboards.sorted { $0.itemCount > $1.itemCount }
    }
}
