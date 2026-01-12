//
//  PinboardDetailView.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI

/// Detail view showing items within a specific pinboard
struct PinboardDetailView: View {
    let pinboard: Pinboard
    @Bindable var viewModel: PinboardViewModel
    @State private var selectedItem: ClipboardItem?
    @State private var showingShareSheet = false
    @State private var clipboardVM = ClipboardListViewModel()
    
    var body: some View {
        Group {
            if items.isEmpty {
                emptyStateView
            } else {
                listView
            }
        }
        .navigationTitle(pinboard.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if pinboard.isShared {
                        Button {
                            viewModel.stopSharing(pinboard)
                        } label: {
                            Label("Stop Sharing", systemImage: "person.badge.minus")
                        }
                    } else {
                        Button {
                            Task {
                                await viewModel.sharePinboard(pinboard)
                            }
                        } label: {
                            Label("Share Pinboard", systemImage: "person.badge.plus")
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        viewModel.deletePinboard(pinboard)
                    } label: {
                        Label("Delete Pinboard", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            NavigationStack {
                DetailView(item: item, viewModel: clipboardVM)
            }
        }
        .onAppear {
            viewModel.selectPinboard(pinboard)
        }
    }
    
    private var items: [ClipboardItem] {
        viewModel.selectedPinboardItems
    }
    
    // MARK: - List View
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Pinboard header
                headerView
                
                ForEach(items) { item in
                    ClipboardItemRow(
                        item: item,
                        onTap: { selectedItem = item },
                        onCopy: { clipboardVM.copyToClipboard(item) },
                        onDelete: { viewModel.removeItem(item, from: pinboard) }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(pinboard.displayColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: pinboard.iconName)
                    .font(.title)
                    .foregroundStyle(pinboard.displayColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(pinboard.name)
                        .font(.title2.weight(.semibold))
                    
                    if pinboard.isShared {
                        Image(systemName: pinboard.shareStatus.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("\(pinboard.itemCount) items · Created \(pinboard.formattedCreationDate)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Show header even when empty
            headerView
                .padding(.horizontal)
            
            Spacer()
            
            ContentUnavailableView {
                Label("No Items", systemImage: "tray")
            } description: {
                Text("Add items to this pinboard from your clipboard history.")
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        PinboardDetailView(
            pinboard: .sampleWork,
            viewModel: PinboardViewModel()
        )
    }
}
