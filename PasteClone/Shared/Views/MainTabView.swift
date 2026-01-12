//
//  MainTabView.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI

/// Root tab view for the application
struct MainTabView: View {
    @State private var selectedTab: Tab = .history
    @State private var clipboardVM = ClipboardListViewModel()
    @State private var pinboardVM = PinboardViewModel()
    @State private var searchVM = SearchViewModel()
    @State private var settingsVM = SettingsViewModel()
    
    enum Tab: String, CaseIterable {
        case history = "History"
        case pinboards = "Pinboards"
        case search = "Search"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .history: return "clock.fill"
            case .pinboards: return "pin.fill"
            case .search: return "magnifyingglass"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // History Tab
            NavigationStack {
                ClipboardListView(viewModel: clipboardVM)
            }
            .tabItem {
                Label(Tab.history.rawValue, systemImage: Tab.history.icon)
            }
            .tag(Tab.history)
            
            // Pinboards Tab
            NavigationStack {
                PinboardListView(viewModel: pinboardVM)
            }
            .tabItem {
                Label(Tab.pinboards.rawValue, systemImage: Tab.pinboards.icon)
            }
            .tag(Tab.pinboards)
            
            // Search Tab
            NavigationStack {
                SearchView(viewModel: searchVM)
            }
            .tabItem {
                Label(Tab.search.rawValue, systemImage: Tab.search.icon)
            }
            .tag(Tab.search)
            
            // Settings Tab
            NavigationStack {
                SettingsView(viewModel: settingsVM)
            }
            .tabItem {
                Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
            }
            .tag(Tab.settings)
        }
        .tint(.accentColor)
        .onAppear {
            // Start clipboard monitoring when app appears
            ClipboardMonitor.shared.startMonitoring()
        }
    }
}

#Preview {
    MainTabView()
}
