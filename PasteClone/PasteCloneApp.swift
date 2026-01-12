//
//  PasteCloneApp.swift
//  PasteClone
//
//  ClipKeep - Clipboard Manager for iOS 26
//

import SwiftUI

@main
struct PasteCloneApp: App {
    /// User settings
    @State private var settings = UserSettings.shared
    
    /// Whether onboarding has been completed
    @State private var hasCompletedOnboarding = UserSettings.shared.hasCompletedOnboarding
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .preferredColorScheme(settings.theme.colorScheme)
            .onAppear {
                setupApp()
            }
        }
    }
    
    /// Initial app setup
    private func setupApp() {
        // Initialize storage manager (triggers cleanup if needed)
        _ = StorageManager.shared
        
        // Initialize rule manager
        _ = RuleManager.shared
        
        // Start clipboard monitoring
        ClipboardMonitor.shared.startMonitoring()
        
        // Initialize sync manager if enabled
        if settings.syncEnabled {
            Task {
                await SyncManager.shared.sync()
            }
        }
    }
}
