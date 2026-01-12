//
//  Pinboard.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import Foundation
import SwiftUI

/// Represents the sharing status of a pinboard
enum PinboardShareStatus: String, Codable, CaseIterable {
    case `private` = "private"
    case shared = "shared"
    case viewOnly = "viewOnly"
    
    var displayName: String {
        switch self {
        case .private: return "Private"
        case .shared: return "Shared"
        case .viewOnly: return "View Only"
        }
    }
    
    var icon: String {
        switch self {
        case .private: return "lock.fill"
        case .shared: return "person.2.fill"
        case .viewOnly: return "eye.fill"
        }
    }
}

/// Represents a collection of pinned clipboard items
struct Pinboard: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var itemIds: [UUID]
    let creationDate: Date
    var modifiedDate: Date
    var shareStatus: PinboardShareStatus
    var iconName: String
    var color: String
    var sortOrder: Int
    
    /// CloudKit share metadata for collaboration
    var cloudKitShareURL: String?
    var sharedWithUserIds: [String]
    
    init(
        id: UUID = UUID(),
        name: String,
        itemIds: [UUID] = [],
        creationDate: Date = Date(),
        modifiedDate: Date = Date(),
        shareStatus: PinboardShareStatus = .private,
        iconName: String = "pin.fill",
        color: String = "blue",
        sortOrder: Int = 0,
        cloudKitShareURL: String? = nil,
        sharedWithUserIds: [String] = []
    ) {
        self.id = id
        self.name = name
        self.itemIds = itemIds
        self.creationDate = creationDate
        self.modifiedDate = modifiedDate
        self.shareStatus = shareStatus
        self.iconName = iconName
        self.color = color
        self.sortOrder = sortOrder
        self.cloudKitShareURL = cloudKitShareURL
        self.sharedWithUserIds = sharedWithUserIds
    }
    
    // MARK: - Computed Properties
    
    var itemCount: Int {
        itemIds.count
    }
    
    var isShared: Bool {
        shareStatus != .private
    }
    
    var displayColor: Color {
        switch color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
    
    var formattedCreationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: creationDate)
    }
    
    // MARK: - Mutations
    
    mutating func addItem(_ itemId: UUID) {
        guard !itemIds.contains(itemId) else { return }
        itemIds.append(itemId)
        modifiedDate = Date()
    }
    
    mutating func removeItem(_ itemId: UUID) {
        itemIds.removeAll { $0 == itemId }
        modifiedDate = Date()
    }
    
    mutating func reorderItems(_ newOrder: [UUID]) {
        itemIds = newOrder
        modifiedDate = Date()
    }
    
    mutating func rename(to newName: String) {
        name = newName
        modifiedDate = Date()
    }
    
    mutating func setColor(_ newColor: String) {
        color = newColor
        modifiedDate = Date()
    }
    
    mutating func setIcon(_ newIcon: String) {
        iconName = newIcon
        modifiedDate = Date()
    }
}

// MARK: - Available Colors

extension Pinboard {
    static let availableColors = [
        "red", "orange", "yellow", "green", "blue", "purple", "pink"
    ]
    
    static let availableIcons = [
        "pin.fill", "star.fill", "heart.fill", "bookmark.fill",
        "folder.fill", "doc.fill", "link", "photo.fill",
        "code.square.fill", "briefcase.fill", "cart.fill", "house.fill"
    ]
}

// MARK: - Sample Data for Previews

extension Pinboard {
    static let sampleWork = Pinboard(
        name: "Work",
        iconName: "briefcase.fill",
        color: "blue",
        sortOrder: 0
    )
    
    static let samplePersonal = Pinboard(
        name: "Personal",
        iconName: "heart.fill",
        color: "pink",
        sortOrder: 1
    )
    
    static let sampleCode = Pinboard(
        name: "Code Snippets",
        iconName: "code.square.fill",
        color: "purple",
        sortOrder: 2
    )
    
    static let samplePinboards: [Pinboard] = [
        .sampleWork,
        .samplePersonal,
        .sampleCode,
        Pinboard(name: "Links", iconName: "link", color: "green", sortOrder: 3),
        Pinboard(name: "Shopping", iconName: "cart.fill", color: "orange", sortOrder: 4)
    ]
}
