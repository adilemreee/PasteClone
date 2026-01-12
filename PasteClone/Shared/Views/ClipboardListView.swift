//
//  ClipboardListView.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI

/// Main clipboard history list view
struct ClipboardListView: View {
    @Bindable var viewModel: ClipboardListViewModel
    @State private var showingClearConfirmation = false
    @State private var selectedItem: ClipboardItem?
    
    var body: some View {
        Group {
            if viewModel.groupedItems.isEmpty {
                emptyStateView
            } else {
                listView
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if viewModel.isMultiSelectMode {
                        Button("Select All", systemImage: "checkmark.circle.fill") {
                            viewModel.selectAll()
                        }
                        Button("Clear Selection", systemImage: "xmark.circle") {
                            viewModel.clearSelection()
                        }
                        Divider()
                        Button("Delete Selected", systemImage: "trash", role: .destructive) {
                            viewModel.deleteSelected()
                        }
                    } else {
                        Button("Select Items", systemImage: "checkmark.circle") {
                            viewModel.isMultiSelectMode = true
                        }
                        Divider()
                        Button("Clear All History", systemImage: "trash", role: .destructive) {
                            showingClearConfirmation = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Clear All History?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                viewModel.clearAllHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all clipboard history except pinned items.")
        }
        .sheet(item: $selectedItem) { item in
            NavigationStack {
                DetailView(item: item, viewModel: viewModel)
            }
        }
        .refreshable {
            viewModel.refresh()
        }
    }
    
    // MARK: - List View
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                ForEach(viewModel.groupedItems, id: \.date) { group in
                    Section {
                        ForEach(group.items) { item in
                            ClipboardItemRow(
                                item: item,
                                isSelected: viewModel.isSelected(item),
                                isMultiSelectMode: viewModel.isMultiSelectMode,
                                onTap: {
                                    if viewModel.isMultiSelectMode {
                                        viewModel.toggleSelection(item)
                                    } else {
                                        selectedItem = item
                                    }
                                },
                                onCopy: { viewModel.copyToClipboard(item) },
                                onDelete: { viewModel.delete(item) },
                                onPin: { pinboard in
                                    viewModel.pin(item, to: pinboard)
                                },
                                availablePinboards: viewModel.availablePinboards
                            )
                        }
                    } header: {
                        sectionHeader(for: group.date)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(for date: Date) -> some View {
        HStack {
            Text(viewModel.sectionTitle(for: date))
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(.background)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Clipboard History", systemImage: "clipboard")
        } description: {
            Text("Items you copy will appear here.")
        } actions: {
            Button("Copy Something") {
                // Just a hint, no action needed
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    NavigationStack {
        ClipboardListView(viewModel: ClipboardListViewModel())
    }
}
