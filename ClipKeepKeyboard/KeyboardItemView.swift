//
//  KeyboardItemView.swift
//  ClipboardKeyboard
//
//  Created for ClipKeep - Clipboard Manager Keyboard Extension
//

import SwiftUI

/// Compact view for displaying a clipboard item in the keyboard - iOS 26 style
struct KeyboardItemView: View {
    let item: ClipboardItem
    var compact: Bool = false
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                // Content preview
                contentPreview
                
                // Timestamp
                Text(item.formattedTimestamp)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .frame(width: compact ? 100 : 140, height: compact ? 80 : 100, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .secondarySystemBackground).opacity(0.8))
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var contentPreview: some View {
        switch item.type {
        case .text:
            Text(item.previewText ?? item.rawData)
                .font(.subheadline)
                .lineLimit(compact ? 2 : 3)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
        case .link:
            VStack(alignment: .leading, spacing: 2) {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(item.linkTitle ?? item.rawData)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
            }
            
        case .image:
            if let thumbnailData = item.thumbnailData,
               let data = Data(base64Encoded: thumbnailData),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                VStack {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Image")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
        case .file:
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "doc.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text(item.fileName ?? "File")
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    HStack(spacing: 10) {
        KeyboardItemView(
            item: ClipboardItem(
                type: .text,
                rawData: "Sample text content here",
                previewText: "Sample text content here"
            ),
            onTap: {}
        )
        
        KeyboardItemView(
            item: ClipboardItem(
                type: .link,
                rawData: "https://apple.com",
                linkTitle: "Apple"
            ),
            onTap: {}
        )
    }
    .padding()
    .background(.ultraThinMaterial)
}
