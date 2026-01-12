//
//  KeyboardView.swift
//  ClipboardKeyboard
//
//  Created for ClipKeep - Clipboard Manager Keyboard Extension
//

import SwiftUI

/// Main SwiftUI view for the keyboard extension
struct KeyboardView: View {
    @Bindable var dataProvider: KeyboardDataProvider
    var onItemSelected: (ClipboardItem) -> Void
    var onNextKeyboard: () -> Void
    
    @State private var selectedTab: KeyboardTab = .recent
    
    enum KeyboardTab: String, CaseIterable {
        case recent = "Recent"
        case pinboards = "Pinboards"
        
        var icon: String {
            switch self {
            case .recent: return "clock"
            case .pinboards: return "pin"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with tabs and controls
            headerView
            
            // Content
            contentView
            
            // Footer with keyboard controls
            footerView
        }
        .background(Color(.secondarySystemBackground))
        .onAppear {
            dataProvider.refresh()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 16) {
            // Tab picker
            ForEach(KeyboardTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.caption)
                        Text(tab.rawValue)
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedTab == tab ? Color.accentColor : Color.clear)
                    .foregroundStyle(selectedTab == tab ? .white : .primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Refresh button
            Button {
                dataProvider.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .recent:
            recentItemsView
        case .pinboards:
            pinboardsView
        }
    }
    
    private var recentItemsView: some View {
        Group {
            if dataProvider.recentItems.isEmpty {
                emptyStateView("No recent items")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(dataProvider.recentItems) { item in
                            KeyboardItemView(item: item) {
                                onItemSelected(item)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
        .frame(height: 160)
    }
    
    private var pinboardsView: some View {
        Group {
            if dataProvider.pinboards.isEmpty {
                emptyStateView("No pinboards")
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(dataProvider.pinboards) { pinboard in
                            pinboardRow(pinboard)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(height: 160)
    }
    
    private func pinboardRow(_ pinboard: Pinboard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pinboard header
            HStack(spacing: 6) {
                Image(systemName: pinboard.iconName)
                    .font(.caption)
                    .foregroundStyle(pinboard.displayColor)
                
                Text(pinboard.name)
                    .font(.caption.weight(.medium))
                
                Spacer()
                
                Text("\(pinboard.itemCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            
            // Items in pinboard
            if !pinboard.itemIds.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 6) {
                        ForEach(dataProvider.items(for: pinboard)) { item in
                            KeyboardItemView(item: item, compact: true) {
                                onItemSelected(item)
                            }
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func emptyStateView(_ message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            // Globe button to switch keyboards
            Button(action: onNextKeyboard) {
                Image(systemName: "globe")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 36)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // App icon / branding
            HStack(spacing: 4) {
                Image(systemName: "clipboard")
                    .font(.caption2)
                Text("ClipKeep")
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(.secondary)
            
            Spacer()
            
            // Dismiss keyboard button
            Button {
                // This would dismiss the keyboard if possible
                // Not directly accessible from extension
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemBackground))
    }
}

#Preview {
    KeyboardView(
        dataProvider: KeyboardDataProvider(),
        onItemSelected: { _ in },
        onNextKeyboard: {}
    )
    .frame(height: 280)
}
