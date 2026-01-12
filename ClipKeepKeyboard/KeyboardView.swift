//
//  KeyboardView.swift
//  ClipboardKeyboard
//
//  Created for ClipKeep - Clipboard Manager Keyboard Extension
//

import SwiftUI

/// Main SwiftUI view for the keyboard extension - iOS 26 Native Style
struct KeyboardView: View {
    @Bindable var dataProvider: KeyboardDataProvider
    var onItemSelected: (ClipboardItem) -> Void
    var onNextKeyboard: () -> Void
    var onSpace: () -> Void
    var onDelete: () -> Void
    var onReturn: () -> Void
    
    @State private var showingDropdown = false
    @State private var selectedCategory: Category = .clipboard
    
    enum Category: String, CaseIterable {
        case clipboard = "Clipboard"
        case pinboards = "Pinboards"
        
        var icon: String {
            switch self {
            case .clipboard: return "clock.arrow.circlepath"
            case .pinboards: return "pin.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area with frosted glass effect
            mainContentArea
            
            // Bottom bar with space, delete, go
            bottomBar
        }
        .background(Color.clear)
    }
    
    // MARK: - Main Content Area
    
    private var mainContentArea: some View {
        VStack(spacing: 12) {
            // Header with search and category selector
            headerBar
            
            // Content
            contentArea
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }
    
    private var headerBar: some View {
        HStack {
            // Search button
            Button {
                // Search action
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Category selector
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingDropdown.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedCategory.icon)
                        .font(.body)
                    Text(selectedCategory.rawValue)
                        .font(.body.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 28, height: 28)
        }
    }
    
    @ViewBuilder
    private var contentArea: some View {
        let items = selectedCategory == .clipboard 
            ? dataProvider.recentItems 
            : dataProvider.allItems
        
        if items.isEmpty {
            // Empty state
            VStack {
                Spacer()
                Text("History is empty")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(height: 180)
        } else {
            // Items grid/list
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(items) { item in
                        KeyboardItemView(item: item) {
                            onItemSelected(item)
                        }
                    }
                }
            }
            .frame(height: 180)
        }
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        HStack(spacing: 8) {
            // Space bar
            Button {
                onSpace()
            } label: {
                Text("space")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            
            // Delete button
            Button {
                onDelete()
            } label: {
                Image(systemName: "delete.left.fill")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 60, height: 44)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            
            // Go button
            Button {
                onReturn()
            } label: {
                Text("go")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 70, height: 44)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

#Preview {
    KeyboardView(
        dataProvider: KeyboardDataProvider(),
        onItemSelected: { _ in },
        onNextKeyboard: {},
        onSpace: {},
        onDelete: {},
        onReturn: {}
    )
    .frame(height: 300)
    .background(Color.gray.opacity(0.3))
}
