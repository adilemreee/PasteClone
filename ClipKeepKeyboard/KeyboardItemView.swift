//
//  KeyboardItemView.swift
//  ClipboardKeyboard
//
//  Created for ClipKeep - Clipboard Manager Keyboard Extension
//

import SwiftUI

/// Compact item view for the keyboard extension
struct KeyboardItemView: View {
    let item: ClipboardItem
    var compact: Bool = false
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                // Type indicator
                HStack(spacing: 4) {
                    Image(systemName: item.type.icon)
                        .font(.caption2)
                        .foregroundStyle(item.type.color)
                    
                    if !compact {
                        Text(item.type.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer(minLength: 0)
                }
                
                // Content preview
                contentPreview
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .frame(width: compact ? 100 : 140, height: compact ? 60 : 100)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var contentPreview: some View {
        switch item.type {
        case .text:
            Text(item.previewText ?? item.rawData)
                .font(.caption)
                .lineLimit(compact ? 2 : 4)
                .multilineTextAlignment(.leading)
            
        case .link:
            VStack(alignment: .leading, spacing: 2) {
                if let title = item.linkTitle, !compact {
                    Text(title)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                }
                Text(item.rawData)
                    .font(.caption2)
                    .foregroundStyle(.blue)
                    .lineLimit(compact ? 1 : 2)
            }
            
        case .image:
            if let thumbnailData = item.thumbnailData,
               let data = Data(base64Encoded: thumbnailData),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: compact ? 35 : 60)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: compact ? 35 : 60)
            }
            
        case .file:
            HStack(spacing: 4) {
                Image(systemName: "doc.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(item.fileName ?? "File")
                    .font(.caption)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        KeyboardItemView(item: .sampleText, onTap: {})
        KeyboardItemView(item: .sampleLink, onTap: {})
        KeyboardItemView(item: .sampleText, compact: true, onTap: {})
    }
    .padding()
    .background(Color(.secondarySystemBackground))
}
