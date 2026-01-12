//
//  ClipboardItem.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import Foundation
import SwiftUI

/// Represents the type of content stored in a clipboard item
enum ClipboardItemType: String, Codable, CaseIterable, Identifiable {
    case text = "text"
    case image = "image"
    case link = "link"
    case file = "file"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .link: return "link"
        case .file: return "doc"
        }
    }
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .link: return "Link"
        case .file: return "File"
        }
    }
    
    var color: Color {
        switch self {
        case .text: return .blue
        case .image: return .purple
        case .link: return .green
        case .file: return .orange
        }
    }
}

/// Represents a single clipboard item with its content and metadata
struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let type: ClipboardItemType
    
    /// Raw content - Base64 encoded for binary data
    let rawData: String
    
    /// Preview text for display (first few lines for text, alt text for images)
    var previewText: String?
    
    /// Bundle identifier of the app where content was copied
    var sourceAppIdentifier: String?
    
    /// User-defined tags for organization
    var tags: [String]
    
    /// For links: extracted title
    var linkTitle: String?
    
    /// For links: extracted favicon URL
    var faviconURL: String?
    
    /// For files: original filename
    var fileName: String?
    
    /// For images: thumbnail data (Base64)
    var thumbnailData: String?
    
    /// Whether item is pinned to a pinboard
    var isPinned: Bool
    
    /// IDs of pinboards this item belongs to
    var pinboardIds: [UUID]
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: ClipboardItemType,
        rawData: String,
        previewText: String? = nil,
        sourceAppIdentifier: String? = nil,
        tags: [String] = [],
        linkTitle: String? = nil,
        faviconURL: String? = nil,
        fileName: String? = nil,
        thumbnailData: String? = nil,
        isPinned: Bool = false,
        pinboardIds: [UUID] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.rawData = rawData
        self.previewText = previewText
        self.sourceAppIdentifier = sourceAppIdentifier
        self.tags = tags
        self.linkTitle = linkTitle
        self.faviconURL = faviconURL
        self.fileName = fileName
        self.thumbnailData = thumbnailData
        self.isPinned = isPinned
        self.pinboardIds = pinboardIds
    }
    
    /// Create a text clipboard item
    static func text(_ content: String, from app: String? = nil) -> ClipboardItem {
        let preview = String(content.prefix(200))
        return ClipboardItem(
            type: .text,
            rawData: content,
            previewText: preview,
            sourceAppIdentifier: app
        )
    }
    
    /// Create an image clipboard item
    static func image(data: Data, thumbnail: Data? = nil, from app: String? = nil) -> ClipboardItem {
        return ClipboardItem(
            type: .image,
            rawData: data.base64EncodedString(),
            previewText: "Image",
            sourceAppIdentifier: app,
            thumbnailData: thumbnail?.base64EncodedString()
        )
    }
    
    /// Create a link clipboard item
    static func link(_ url: String, title: String? = nil, from app: String? = nil) -> ClipboardItem {
        return ClipboardItem(
            type: .link,
            rawData: url,
            previewText: title ?? url,
            sourceAppIdentifier: app,
            linkTitle: title
        )
    }
    
    /// Create a file clipboard item
    static func file(url: URL, from app: String? = nil) -> ClipboardItem {
        return ClipboardItem(
            type: .file,
            rawData: url.absoluteString,
            previewText: url.lastPathComponent,
            sourceAppIdentifier: app,
            fileName: url.lastPathComponent
        )
    }
    
    // MARK: - Computed Properties
    
    /// Get text content if this is a text item
    var textContent: String? {
        guard type == .text || type == .link else { return nil }
        return rawData
    }
    
    /// Get image data if this is an image item
    var imageData: Data? {
        guard type == .image else { return nil }
        return Data(base64Encoded: rawData)
    }
    
    /// Get URL if this is a link or file item
    var url: URL? {
        guard type == .link || type == .file else { return nil }
        return URL(string: rawData)
    }
    
    /// Formatted timestamp for display
    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    /// Full formatted date
    var fullFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Sample Data for Previews

extension ClipboardItem {
    static let sampleText = ClipboardItem.text(
        "Hello, this is a sample clipboard item with some text content that demonstrates how text items are displayed in the app.",
        from: "com.apple.Notes"
    )
    
    static let sampleLink = ClipboardItem.link(
        "https://www.apple.com",
        title: "Apple",
        from: "com.apple.Safari"
    )
    
    static let sampleItems: [ClipboardItem] = [
        .text("Quick note to self", from: "com.apple.Notes"),
        .link("https://github.com", title: "GitHub", from: "com.apple.Safari"),
        .text("func greet() { print(\"Hello, World!\") }", from: "com.apple.dt.Xcode"),
        .link("https://developer.apple.com", title: "Apple Developer", from: "com.apple.Safari"),
        .text("Meeting at 3pm tomorrow\n- Discuss project timeline\n- Review mockups", from: "com.apple.Notes")
    ]
}
