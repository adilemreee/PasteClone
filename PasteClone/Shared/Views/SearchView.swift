//
//  SearchView.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI

/// Search view for finding clipboard items
struct SearchView: View {
    @Bindable var viewModel: SearchViewModel
    @State private var selectedItem: ClipboardItem?
    @State private var clipboardVM = ClipboardListViewModel()
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar
            
            // Quick filters
            quickFilters
            
            // Content
            if viewModel.query.isEmpty && viewModel.activeQuickFilter == nil {
                recentSearchesView
            } else {
                resultsView
            }
        }
        .navigationTitle("Search")
        .sheet(item: $selectedItem) { item in
            NavigationStack {
                DetailView(item: item, viewModel: clipboardVM)
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search clipboard history", text: $viewModel.query)
                    .focused($isSearchFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        viewModel.saveSearch()
                    }
                
                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if isSearchFocused {
                Button("Cancel") {
                    isSearchFocused = false
                    viewModel.clearSearch()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Quick Filters
    
    private var quickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.quickFilters) { filter in
                    Button {
                        viewModel.applyQuickFilter(filter)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: filter.icon)
                            Text(filter.rawValue)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.isQuickFilterActive(filter)
                            ? Color.accentColor
                            : Color(.secondarySystemBackground)
                        )
                        .foregroundStyle(
                            viewModel.isQuickFilterActive(filter)
                            ? .white
                            : .primary
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                
                // Type filters
                Divider()
                    .frame(height: 20)
                
                ForEach(ClipboardItemType.allCases) { type in
                    Button {
                        viewModel.toggleTypeFilter(type)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.isTypeFilterActive(type)
                            ? type.color
                            : Color(.secondarySystemBackground)
                        )
                        .foregroundStyle(
                            viewModel.isTypeFilterActive(type)
                            ? .white
                            : .primary
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
        Group {
            if viewModel.isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.results.isEmpty {
                ContentUnavailableView.search(text: viewModel.query)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Results count
                        HStack {
                            Text(viewModel.statusMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        
                        ForEach(viewModel.results) { item in
                            ClipboardItemRow(
                                item: item,
                                onTap: { selectedItem = item },
                                onCopy: { clipboardVM.copyToClipboard(item) },
                                onDelete: { clipboardVM.delete(item); viewModel.search() }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Recent Searches
    
    private var recentSearchesView: some View {
        Group {
            if viewModel.recentSearches.isEmpty {
                ContentUnavailableView {
                    Label("Search History", systemImage: "magnifyingglass")
                } description: {
                    Text("Your recent searches will appear here.")
                }
            } else {
                List {
                    Section("Recent Searches") {
                        ForEach(viewModel.recentSearches, id: \.self) { search in
                            Button {
                                viewModel.useSuggestion(search)
                            } label: {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundStyle(.secondary)
                                    Text(search)
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) {
                                    viewModel.removeRecentSearch(search)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    
                    Section {
                        Button("Clear Recent Searches", role: .destructive) {
                            viewModel.clearRecentSearches()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchView(viewModel: SearchViewModel())
    }
}
