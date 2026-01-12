//
//  ClipboardItemRow.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI

/// Individual clipboard item row/card view
struct ClipboardItemRow: View {
    let item: ClipboardItem
    var isSelected: Bool = false
    var isMultiSelectMode: Bool = false
    var onTap: () -> Void = {}
    var onCopy: () -> Void = {}
    var onDelete: () -> Void = {}
    var onPin: (Pinboard) -> Void = { _ in }
    var availablePinboards: [Pinboard] = []
    
    @State private var showingShareSheet = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Selection indicator
                if isMultiSelectMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                        .font(.title2)
                }
                
                // Type icon
                typeIcon
                
                // Content preview
                VStack(alignment: .leading, spacing: 4) {
                    contentPreview
                    
                    // Metadata row
                    HStack(spacing: 8) {
                        Text(item.formattedTimestamp)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if item.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        
                        if !item.tags.isEmpty {
                            Text(item.tags.first ?? "")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer(minLength: 0)
                
                // Quick actions
                if !isMultiSelectMode {
                    quickActions
                }
            }
            .padding()
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            contextMenuItems
        }
    }
    
    // MARK: - Type Icon
    
    private var typeIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(item.type.color.opacity(0.15))
                .frame(width: 44, height: 44)
            
            Image(systemName: item.type.icon)
                .font(.title3)
                .foregroundStyle(item.type.color)
        }
    }
    
    // MARK: - Content Preview
    
    @ViewBuilder
    private var contentPreview: some View {
        switch item.type {
        case .text:
            Text(item.previewText ?? item.rawData)
                .font(.body)
                .lineLimit(2)
                .foregroundStyle(.primary)
            
        case .link:
            VStack(alignment: .leading, spacing: 2) {
                if let title = item.linkTitle {
                    Text(title)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                }
                Text(item.rawData)
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
            }
            
        case .image:
            HStack {
                if let thumbnailData = item.thumbnailData,
                   let data = Data(base64Encoded: thumbnailData),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Text("Image")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
        case .file:
            VStack(alignment: .leading, spacing: 2) {
                Text(item.fileName ?? "File")
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                if let url = item.url {
                    Text(url.pathExtension.uppercased())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        HStack(spacing: 12) {
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private var contextMenuItems: some View {
        Button(action: onCopy) {
            Label("Copy", systemImage: "doc.on.doc")
        }
        
        if !availablePinboards.isEmpty {
            Menu("Add to Pinboard") {
                ForEach(availablePinboards) { pinboard in
                    Button {
                        onPin(pinboard)
                    } label: {
                        Label(pinboard.name, systemImage: pinboard.iconName)
                    }
                }
            }
        }
        
        Button {
            showingShareSheet = true
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        
        Divider()
        
        Button(role: .destructive, action: onDelete) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Background
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.background)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ClipboardItemRow(
            item: .sampleText,
            onTap: {},
            onCopy: {},
            onDelete: {}
        )
        
        ClipboardItemRow(
            item: .sampleLink,
            onTap: {},
            onCopy: {},
            onDelete: {}
        )
        
        ClipboardItemRow(
            item: .sampleText,
            isSelected: true,
            isMultiSelectMode: true,
            onTap: {},
            onCopy: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
