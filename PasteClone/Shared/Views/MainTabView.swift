//
//  MainTabView.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI

/// Root view for the application - Paste app style
struct MainTabView: View {
    @State private var clipboardVM = ClipboardListViewModel()
    @State private var pinboardVM = PinboardViewModel()
    @State private var searchVM = SearchViewModel()
    @State private var settingsVM = SettingsViewModel()
    
    @State private var selectedPinboard: Pinboard?
    @State private var showingPinboardPicker = false
    @State private var showingSettings = false
    @State private var showingFilters = false
    @State private var searchText = ""
    @State private var isSearching = false
    
    // Filter states
    @State private var selectedTypes: Set<ClipboardItemType> = []
    @State private var selectedDateFilter: FilterSheet.DateFilter?
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $searchText, isPresented: $isSearching, prompt: "Search")
                .onChange(of: searchText) { _, newValue in
                    searchVM.query = newValue
                }
                .toolbar {
                    // Top bar - right side
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            Button("Select") {
                                clipboardVM.isMultiSelectMode.toggle()
                            }
                            .foregroundStyle(.primary)
                            
                            Menu {
                                Button {
                                    showingSettings = true
                                } label: {
                                    Label("Settings", systemImage: "gearshape")
                                }
                                
                                Button {
                                    // Help action
                                } label: {
                                    Label("Help", systemImage: "questionmark.circle")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    
                    // Bottom toolbar - Search
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                    
                    // Bottom toolbar - Spacer
                    ToolbarItem(placement: .bottomBar) {
                        Spacer()
                    }
                    
                    // Bottom toolbar - Pinboard selector (center)
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            showingPinboardPicker = true
                        } label: {
                            HStack(spacing: 6) {
                                if let pinboard = selectedPinboard {
                                    Circle()
                                        .fill(pinboard.displayColor)
                                        .frame(width: 10, height: 10)
                                    Text(pinboard.name)
                                } else {
                                    Image(systemName: "clock.arrow.circlepath")
                                    Text("Clipboard")
                                }
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                            }
                        }
                    }
                    
                    // Bottom toolbar - Spacer
                    ToolbarItem(placement: .bottomBar) {
                        Spacer()
                    }
                    
                    // Bottom toolbar - Add button
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            // Add new item action
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingPinboardPicker) {
                    PinboardPickerSheet(
                        selectedPinboard: $selectedPinboard,
                        viewModel: pinboardVM,
                        isPresented: $showingPinboardPicker
                    )
                }
                .sheet(isPresented: $showingSettings) {
                    NavigationStack {
                        SettingsView(viewModel: settingsVM)
                    }
                }
                .sheet(isPresented: $showingFilters) {
                    FilterSheet(
                        selectedTypes: $selectedTypes,
                        selectedDateFilter: $selectedDateFilter,
                        isPresented: $showingFilters
                    )
                }
                .onChange(of: selectedTypes) { _, newValue in
                    searchVM.typeFilters = newValue
                }
        }
        .onAppear {
            ClipboardMonitor.shared.startMonitoring()
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        if isSearching || !searchText.isEmpty {
            // Search results with filter button
            searchResultsView
                .searchScopes($searchVM.activeQuickFilter) {
                    Text("All").tag(Optional<SearchManager.QuickFilter>.none)
                    Text("Today").tag(Optional<SearchManager.QuickFilter>.some(.today))
                    Text("Links").tag(Optional<SearchManager.QuickFilter>.some(.links))
                    Text("Images").tag(Optional<SearchManager.QuickFilter>.some(.images))
                }
        } else if let pinboard = selectedPinboard {
            PinboardDetailView(pinboard: pinboard, viewModel: pinboardVM)
        } else {
            ClipboardListView(viewModel: clipboardVM)
        }
    }
    
    // MARK: - Search Results View
    
    private var searchResultsView: some View {
        Group {
            if searchVM.results.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if searchVM.results.isEmpty {
                ContentUnavailableView {
                    Label("Search", systemImage: "magnifyingglass")
                } description: {
                    Text("Search across all your clipboard history and pinboards")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchVM.results) { item in
                            ClipboardItemRow(
                                item: item,
                                isSelected: false,
                                isMultiSelectMode: false,
                                onTap: { clipboardVM.copyToClipboard(item) },
                                onCopy: { clipboardVM.copyToClipboard(item) },
                                onDelete: { clipboardVM.delete(item) },
                                onPin: { pinboard in
                                    clipboardVM.pin(item, to: pinboard)
                                },
                                availablePinboards: clipboardVM.availablePinboards
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
