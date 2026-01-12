//
//  SearchViewModel.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import Foundation
import SwiftUI

/// View model for search functionality
@Observable
@MainActor
final class SearchViewModel {
    // MARK: - Properties
    
    /// Current search query
    var query: String = "" {
        didSet {
            searchManager.query = query
        }
    }
    
    /// Search results
    var results: [ClipboardItem] {
        searchManager.results
    }
    
    /// Whether search is in progress
    var isSearching: Bool {
        searchManager.isSearching
    }
    
    /// Recent search queries
    var recentSearches: [String] {
        searchManager.recentSearches
    }
    
    /// Active type filters
    var typeFilters: Set<ClipboardItemType> {
        get { searchManager.typeFilters }
        set { searchManager.typeFilters = newValue }
    }
    
    /// Date range filter
    var dateRange: ClosedRange<Date>? {
        get { searchManager.dateRange }
        set { searchManager.dateRange = newValue }
    }
    
    /// Whether filters are active
    var hasActiveFilters: Bool {
        !typeFilters.isEmpty || dateRange != nil
    }
    
    /// Currently applied quick filter
    var activeQuickFilter: SearchManager.QuickFilter?
    
    /// Search manager reference
    private let searchManager: SearchManager
    
    // MARK: - Initialization
    
    init(searchManager: SearchManager = .shared) {
        self.searchManager = searchManager
    }
    
    // MARK: - Public Methods
    
    /// Perform search with current query
    func search() {
        searchManager.search()
    }
    
    /// Clear search and reset filters
    func clearSearch() {
        query = ""
        activeQuickFilter = nil
        searchManager.clearSearch()
    }
    
    /// Save current query to recent searches
    func saveSearch() {
        searchManager.saveRecentSearch()
    }
    
    /// Remove a recent search
    func removeRecentSearch(_ search: String) {
        searchManager.removeRecentSearch(search)
    }
    
    /// Clear all recent searches
    func clearRecentSearches() {
        searchManager.clearRecentSearches()
    }
    
    /// Toggle type filter
    func toggleTypeFilter(_ type: ClipboardItemType) {
        activeQuickFilter = nil
        searchManager.toggleTypeFilter(type)
    }
    
    /// Clear all type filters
    func clearTypeFilters() {
        typeFilters = []
        search()
    }
    
    /// Set date range filter
    func setDateRange(_ range: ClosedRange<Date>?) {
        activeQuickFilter = nil
        searchManager.setDateRange(range)
    }
    
    /// Clear date filter
    func clearDateFilter() {
        dateRange = nil
        search()
    }
    
    /// Apply a quick filter
    func applyQuickFilter(_ filter: SearchManager.QuickFilter) {
        query = ""
        activeQuickFilter = filter
        searchManager.applyQuickFilter(filter)
    }
    
    /// Get search suggestions
    func suggestions() -> [String] {
        searchManager.suggestions()
    }
    
    /// Set query from suggestion
    func useSuggestion(_ suggestion: String) {
        query = suggestion
        search()
    }
}

// MARK: - Computed Properties

extension SearchViewModel {
    /// Result count
    var resultCount: Int {
        results.count
    }
    
    /// Results grouped by type
    var resultsByType: [ClipboardItemType: [ClipboardItem]] {
        Dictionary(grouping: results) { $0.type }
    }
    
    /// Check if a type filter is active
    func isTypeFilterActive(_ type: ClipboardItemType) -> Bool {
        typeFilters.contains(type)
    }
    
    /// Quick filters
    var quickFilters: [SearchManager.QuickFilter] {
        SearchManager.QuickFilter.allCases
    }
    
    /// Check if a quick filter is active
    func isQuickFilterActive(_ filter: SearchManager.QuickFilter) -> Bool {
        activeQuickFilter == filter
    }
    
    /// Status message for display
    var statusMessage: String {
        if query.isEmpty && !hasActiveFilters && activeQuickFilter == nil {
            return "Search your clipboard history"
        } else if isSearching {
            return "Searching..."
        } else if results.isEmpty {
            return "No results found"
        } else {
            return "\(resultCount) result\(resultCount == 1 ? "" : "s")"
        }
    }
}

// MARK: - Date Filter Presets

extension SearchViewModel {
    enum DateFilterPreset: String, CaseIterable, Identifiable {
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case custom = "Custom"
        
        var id: String { rawValue }
        
        func dateRange() -> ClosedRange<Date>? {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .today:
                let start = calendar.startOfDay(for: now)
                return start...now
                
            case .yesterday:
                guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return nil }
                let start = calendar.startOfDay(for: yesterday)
                let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
                return start...end
                
            case .thisWeek:
                guard let start = calendar.date(byAdding: .day, value: -7, to: now) else { return nil }
                return start...now
                
            case .thisMonth:
                guard let start = calendar.date(byAdding: .month, value: -1, to: now) else { return nil }
                return start...now
                
            case .custom:
                return nil
            }
        }
    }
    
    /// Apply date filter preset
    func applyDatePreset(_ preset: DateFilterPreset) {
        setDateRange(preset.dateRange())
    }
}
