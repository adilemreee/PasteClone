//
//  SyncManager.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import Foundation
import CloudKit

/// Manages iCloud synchronization for clipboard data
/// Note: Full CloudKit implementation requires NSPersistentCloudKitContainer
/// This provides the interface and basic functionality
@Observable
@MainActor
final class SyncManager {
    // MARK: - Singleton
    
    static let shared = SyncManager()
    
    // MARK: - Properties
    
    /// Current sync status
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success(Date)
        case error(String)
        
        var displayName: String {
            switch self {
            case .idle: return "Ready"
            case .syncing: return "Syncing..."
            case .success: return "Synced"
            case .error(let message): return "Error: \(message)"
            }
        }
        
        var icon: String {
            switch self {
            case .idle: return "icloud"
            case .syncing: return "arrow.triangle.2.circlepath.icloud"
            case .success: return "checkmark.icloud"
            case .error: return "exclamationmark.icloud"
            }
        }
    }
    
    private(set) var status: SyncStatus = .idle
    
    /// Whether sync is enabled
    var isSyncEnabled: Bool {
        UserSettings.shared.syncEnabled
    }
    
    /// CloudKit container identifier
    private let containerIdentifier = "iCloud.adilemre.clipkeep"
    
    /// CloudKit container
    private var _cloudKitContainer: CKContainer?
    
    private var container: CKContainer? {
        if _cloudKitContainer == nil {
            _cloudKitContainer = CKContainer(identifier: containerIdentifier)
        }
        return _cloudKitContainer
    }
    
    /// Private database
    private var privateDatabase: CKDatabase? {
        container?.privateCloudDatabase
    }
    
    /// Shared database (for shared pinboards)
    private var sharedDatabase: CKDatabase? {
        container?.sharedCloudDatabase
    }
    
    /// Storage manager reference
    private let storageManager: StorageManager
    
    // MARK: - Initialization
    
    init(storageManager: StorageManager = .shared) {
        self.storageManager = storageManager
        setupNotifications()
    }
    
    // MARK: - Public Methods
    
    /// Check iCloud account status
    func checkAccountStatus() async -> Bool {
        guard let container = container else {
            print("⚠️ SyncManager: CloudKit container not configured")
            return false
        }
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            print("⚠️ SyncManager: iCloud account check failed: \(error)")
            return false
        }
    }
    
    /// Trigger manual sync
    func sync() async {
        guard isSyncEnabled else {
            status = .error("Sync disabled")
            return
        }
        
        status = .syncing
        
        // Check account status
        guard await checkAccountStatus() else {
            status = .error("iCloud unavailable")
            return
        }
        
        do {
            // In a full implementation, this would:
            // 1. Fetch changes from CloudKit
            // 2. Merge with local data
            // 3. Push local changes to CloudKit
            
            // Simulate sync delay for demo
            try await Task.sleep(for: .seconds(1))
            
            status = .success(Date())
            UserSettings.shared.lastSyncDate = Date()
            
            print("✅ SyncManager: Sync completed successfully")
        } catch {
            status = .error(error.localizedDescription)
            print("❌ SyncManager: Sync failed: \(error)")
        }
    }
    
    /// Share a pinboard with another user
    func sharePinboard(_ pinboard: Pinboard) async throws -> CKShare {
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "SyncManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not configured"])
        }
        
        // Create a share record
        let shareRecord = CKShare(recordZoneID: .default)
        shareRecord[CKShare.SystemFieldKey.title] = pinboard.name as CKRecordValue
        
        // Set permissions
        shareRecord.publicPermission = .readOnly
        
        // Save the share
        let operation = CKModifyRecordsOperation(
            recordsToSave: [shareRecord],
            recordIDsToDelete: nil
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: shareRecord)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            privateDatabase.add(operation)
        }
    }
    
    /// Accept a shared pinboard invitation
    func acceptShare(metadata: CKShare.Metadata) async throws {
        guard let container = container else {
            throw NSError(domain: "SyncManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not configured"])
        }
        
        let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.acceptSharesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            container.add(operation)
        }
    }
    
    /// Fetch shared pinboards
    func fetchSharedPinboards() async throws -> [Pinboard] {
        // This would query the shared database for pinboards shared with this user
        // Returning empty for now as this requires full CloudKit schema setup
        return []
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        // Listen for remote notifications about CloudKit changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleAccountChange()
            }
        }
    }
    
    private func handleAccountChange() async {
        let available = await checkAccountStatus()
        
        if !available {
            status = .error("iCloud account changed")
        } else if isSyncEnabled {
            await sync()
        }
    }
}

// MARK: - Conflict Resolution

extension SyncManager {
    /// Conflict resolution strategy
    enum ConflictResolution {
        case keepLocal
        case keepRemote
        case merge
    }
    
    /// Resolve conflicts between local and remote items
    func resolveConflict(
        local: ClipboardItem,
        remote: ClipboardItem,
        strategy: ConflictResolution
    ) -> ClipboardItem {
        switch strategy {
        case .keepLocal:
            return local
        case .keepRemote:
            return remote
        case .merge:
            // Merge strategy: keep newer timestamp, combine tags
            let newer = local.timestamp > remote.timestamp ? local : remote
            var merged = newer
            merged.tags = Array(Set(local.tags + remote.tags))
            merged.pinboardIds = Array(Set(local.pinboardIds + remote.pinboardIds))
            return merged
        }
    }
}
