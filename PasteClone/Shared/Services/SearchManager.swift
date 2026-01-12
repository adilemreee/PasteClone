//
//  SearchManager.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import Foundation
import Combine

/// Manages search functionality with debouncing and caching
@Observable
@MainActor
final class SearchManager {
    // MARK: - Singleton
    
    static let shared = SearchManager()
    
    // MARK: - Properties
    
    /// Current search query
    var query: String = "" {
        didSet { debouncedSearch() }
    }
    
    /// Active type filters
    var typeFilters: Set<ClipboardItemType> = []
    
    /// Date range filter
    var dateRange: ClosedRange<Date>?
    
    /// Search results
    private(set) var results: [ClipboardItem] = []
    
    /// Whether a search is in progress
    private(set) var isSearching = false
    
    /// Recent search queries for suggestions
    private(set) var recentSearches: [String] = []
    
    /// Storage manager reference
    private let storageManager: StorageManager
    
    /// Debounce timer
    private var searchTask: Task<Void, Never>?
    
    /// Debounce delay
    private let debounceDelay: Duration = .milliseconds(300)
    
    /// Maximum recent searches to keep
    private let maxRecentSearches = 20
    
    /// UserDefaults key for recent searches
    private let recentSearchesKey = "recentSearches"
    
    // MARK: - Initialization
    
    init(storageManager: StorageManager = .shared) {
        self.storageManager = storageManager
        loadRecentSearches()
    }
    
    // MARK: - Public Methods
    
    /// Perform search with current query and filters
    func search() {
        guard !query.isEmpty else {
            results = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        // Perform search
        results = storageManager.search(
            query: query,
            types: typeFilters.isEmpty ? nil : typeFilters,
            dateRange: dateRange
        )
        
        isSearching = false
    }
    
    /// Clear search and results
    func clearSearch() {
        searchTask?.cancel()
        query = ""
        results = []
        typeFilters = []
        dateRange = nil
        isSearching = false
    }
    
    /// Set type filter
    func toggleTypeFilter(_ type: ClipboardItemType) {
        if typeFilters.contains(type) {
            typeFilters.remove(type)
        } else {
            typeFilters.insert(type)
        }
        search()
    }
    
    /// Set date range filter
    func setDateRange(_ range: ClosedRange<Date>?) {
        dateRange = range
        search()
    }
    
    /// Add query to recent searches
    func saveRecentSearch() {
        guard !query.isEmpty else { return }
        
        // Remove if already exists (to move to front)
        recentSearches.removeAll { $0.lowercased() == query.lowercased() }
        
        // Add to front
        recentSearches.insert(query, at: 0)
        
        // Trim to max
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        saveRecentSearches()
    }
    
    /// Remove a recent search
    func removeRecentSearch(_ search: String) {
        recentSearches.removeAll { $0 == search }
        saveRecentSearches()
    }
    
    /// Clear all recent searches
    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }
    
    /// Get search suggestions based on current query
    func suggestions() -> [String] {
        guard !query.isEmpty else { return recentSearches }
        
        let lowercasedQuery = query.lowercased()
        return recentSearches.filter { $0.lowercased().contains(lowercasedQuery) }
    }
    
    // MARK: - Private Methods
    
    private func debouncedSearch() {
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            results = []
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            try? await Task.sleep(for: debounceDelay)
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                search()
            }
        }
    }
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }
    
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }
}

// MARK: - Quick Filters

extension SearchManager {
    /// Predefined quick filters
    enum QuickFilter: String, CaseIterable, Identifiable {
        case today = "Today"
        case thisWeek = "This Week"
        case links = "Links"
        case images = "Images"
        case pinned = "Pinned"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .today: return "calendar"
            case .thisWeek: return "calendar.badge.clock"
            case .links: return "link"
            case .images: return "photo"
            case .pinned: return "pin.fill"
            }
        }
    }
    
    /// Apply a quick filter
    func applyQuickFilter(_ filter: QuickFilter) {
        clearSearch()
        
        switch filter {
        case .today:
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: Date())
            let end = Date()
            dateRange = start...end
            
        case .thisWeek:
            let calendar = Calendar.current
            let start = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            dateRange = start...Date()
            
        case .links:
            typeFilters = [.link]
            
        case .images:
            typeFilters = [.image]
            
        case .pinned:
            // Special case: filter to only pinned items
            results = storageManager.items.filter { $0.isPinned }
            return
        }
        
        // Perform search with updated filters
        results = storageManager.search(
            query: "",
            types: typeFilters.isEmpty ? nil : typeFilters,
            dateRange: dateRange
        )
    }
}
