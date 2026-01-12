//
//  ClipboardMonitor.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import Foundation
import UIKit
import Combine

/// Monitors the system clipboard for changes and saves new items
@Observable
@MainActor
final class ClipboardMonitor {
    // MARK: - Singleton
    
    static let shared = ClipboardMonitor()
    
    // MARK: - Properties
    
    /// Whether monitoring is currently active
    private(set) var isMonitoring = false
    
    /// Last known change count from UIPasteboard
    private var lastChangeCount: Int = 0
    
    /// Timer for polling the clipboard
    private var timer: Timer?
    
    /// Polling interval in seconds
    private let pollingInterval: TimeInterval = 1.0
    
    /// Storage manager for persisting items
    private let storageManager: StorageManager
    
    /// Security manager for checking sensitive content
    private let securityManager: SecurityManager
    
    /// Settings for user preferences
    private let settings: UserSettings
    
    /// Recently saved item IDs to avoid duplicates
    private var recentItemHashes: Set<Int> = []
    
    /// Published stream of new clipboard items
    var onNewItem: ((ClipboardItem) -> Void)?
    
    // MARK: - Initialization
    
    init(
        storageManager: StorageManager = .shared,
        securityManager: SecurityManager = .shared,
        settings: UserSettings = .shared
    ) {
        self.storageManager = storageManager
        self.securityManager = securityManager
        self.settings = settings
        self.lastChangeCount = UIPasteboard.general.changeCount
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring the clipboard
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        lastChangeCount = UIPasteboard.general.changeCount
        
        // Start polling timer
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
        
        // Also observe app becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        print("📋 ClipboardMonitor: Started monitoring")
    }
    
    /// Stop monitoring the clipboard
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        
        NotificationCenter.default.removeObserver(self)
        
        print("📋 ClipboardMonitor: Stopped monitoring")
    }
    
    /// Manually check clipboard (useful when app becomes active)
    func checkNow() {
        checkClipboard()
    }
    
    // MARK: - Private Methods
    
    @objc private func appDidBecomeActive() {
        // Check clipboard immediately when app becomes active
        checkClipboard()
    }
    
    private func checkClipboard() {
        let pasteboard = UIPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        // Check if clipboard has changed
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        // Process the new clipboard content
        processClipboardContent(pasteboard)
    }
    
    private func processClipboardContent(_ pasteboard: UIPasteboard) {
        // Try to get text content
        if let text = pasteboard.string, !text.isEmpty {
            processText(text)
            return
        }
        
        // Try to get image content
        if let image = pasteboard.image {
            processImage(image)
            return
        }
        
        // Try to get URL content
        if let url = pasteboard.url {
            processURL(url)
            return
        }
        
        // Try to get file URLs
        if let urls = pasteboard.urls, !urls.isEmpty {
            for url in urls {
                if url.isFileURL {
                    processFile(url)
                } else {
                    processURL(url)
                }
            }
            return
        }
    }
    
    private func processText(_ text: String) {
        // Check against sensitive data rules
        if securityManager.shouldIgnore(text) {
            print("📋 ClipboardMonitor: Content matched ignore rule, skipping")
            
            // If action is clear, clear the clipboard after delay
            if securityManager.shouldClear(text) {
                clearClipboardAfterDelay()
            }
            return
        }
        
        // Check for duplicate
        let hash = text.hashValue
        guard !recentItemHashes.contains(hash) else { return }
        recentItemHashes.insert(hash)
        
        // Limit the size of recent hashes
        if recentItemHashes.count > 100 {
            recentItemHashes.removeFirst()
        }
        
        // Detect if it's a URL
        if let url = URL(string: text), url.scheme != nil {
            let item = ClipboardItem.link(text, title: nil, from: getSourceApp())
            saveItem(item)
        } else {
            let item = ClipboardItem.text(text, from: getSourceApp())
            saveItem(item)
        }
    }
    
    private func processImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        // Create thumbnail
        let thumbnailSize = CGSize(width: 200, height: 200)
        let thumbnail = image.preparingThumbnail(of: thumbnailSize)
        let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.6)
        
        let item = ClipboardItem.image(
            data: imageData,
            thumbnail: thumbnailData,
            from: getSourceApp()
        )
        saveItem(item)
    }
    
    private func processURL(_ url: URL) {
        let item = ClipboardItem.link(
            url.absoluteString,
            title: nil,
            from: getSourceApp()
        )
        saveItem(item)
    }
    
    private func processFile(_ url: URL) {
        let item = ClipboardItem.file(url: url, from: getSourceApp())
        saveItem(item)
    }
    
    private func saveItem(_ item: ClipboardItem) {
        // Save to storage
        storageManager.save(item)
        
        // Notify listeners
        onNewItem?(item)
        
        // Haptic feedback if enabled
        if settings.hapticEnabled {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        print("📋 ClipboardMonitor: Saved new \(item.type.displayName) item")
    }
    
    private func getSourceApp() -> String? {
        // Note: iOS doesn't provide the source app bundle ID directly
        // This would require additional implementation or return nil
        return nil
    }
    
    private func clearClipboardAfterDelay() {
        let delay = Double(settings.sensitiveDataDelay)
        
        Task {
            try? await Task.sleep(for: .seconds(delay))
            await MainActor.run {
                UIPasteboard.general.string = ""
                print("📋 ClipboardMonitor: Cleared clipboard due to sensitive content rule")
            }
        }
    }
}

// MARK: - Background Task Support

extension ClipboardMonitor {
    /// Register for background app refresh
    func registerBackgroundTask() {
        // Background App Refresh registration would go here
        // This requires additional entitlements and Info.plist configuration
    }
}
