//
//  SettingsView.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI

/// Settings and preferences view
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showingClearConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var showingAddRule = false
    @State private var newRuleName = ""
    @State private var newRulePattern = ""
    @State private var newRuleAction: RuleAction = .ignore
    
    var body: some View {
        List {
            // Sync Section
            syncSection
            
            // Appearance Section
            appearanceSection
            
            // Privacy Section
            privacySection
            
            // Rules Section
            rulesSection
            
            // Storage Section
            storageSection
            
            // About Section
            aboutSection
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Clear All History?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                viewModel.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all clipboard history except pinned items.")
        }
        .confirmationDialog(
            "Reset Settings?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                viewModel.resetSettings()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingAddRule) {
            addRuleSheet
        }
    }
    
    // MARK: - Sync Section
    
    private var syncSection: some View {
        Section {
            Toggle("iCloud Sync", isOn: $viewModel.syncEnabled)
            
            if viewModel.syncEnabled {
                HStack {
                    Text("Last Sync")
                    Spacer()
                    Text(viewModel.formattedLastSync)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    Task {
                        await viewModel.triggerSync()
                    }
                } label: {
                    HStack {
                        Label("Sync Now", systemImage: viewModel.syncStatus.icon)
                        Spacer()
                        if case .syncing = viewModel.syncStatus {
                            ProgressView()
                        }
                    }
                }
            }
        } header: {
            Text("Sync")
        } footer: {
            Text("Sync your clipboard history and pinboards across all your devices.")
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $viewModel.theme) {
                ForEach(AppTheme.allCases) { theme in
                    Label(theme.displayName, systemImage: theme.icon)
                        .tag(theme)
                }
            }
            
            Toggle("Show Previews", isOn: $viewModel.showPreviews)
            Toggle("Sound Effects", isOn: $viewModel.soundEnabled)
            Toggle("Haptic Feedback", isOn: $viewModel.hapticEnabled)
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        Section {
            Toggle("Auto-Delete Sensitive Data", isOn: $viewModel.autoDeleteSensitive)
            
            if viewModel.autoDeleteSensitive {
                Picker("Delete Delay", selection: $viewModel.sensitiveDataDelay) {
                    Text("3 seconds").tag(3)
                    Text("5 seconds").tag(5)
                    Text("10 seconds").tag(10)
                    Text("30 seconds").tag(30)
                }
            }
            
            Toggle("Notifications", isOn: $viewModel.notificationsEnabled)
        } header: {
            Text("Privacy")
        } footer: {
            Text("Sensitive data matching your rules will be automatically cleared from the clipboard.")
        }
    }
    
    // MARK: - Rules Section
    
    private var rulesSection: some View {
        Section {
            ForEach(viewModel.rules) { rule in
                ruleRow(rule)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteRule(viewModel.rules[index])
                }
            }
            
            Button {
                resetRuleSheet()
                showingAddRule = true
            } label: {
                Label("Add Rule", systemImage: "plus")
            }
        } header: {
            Text("Sensitive Data Rules")
        } footer: {
            Text("Rules define patterns to detect and handle sensitive content like passwords and credit cards.")
        }
    }
    
    private func ruleRow(_ rule: Rule) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(rule.name)
                        .font(.body)
                    
                    if rule.isBuiltIn {
                        Text("Built-in")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                
                Text(rule.action.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in viewModel.toggleRule(rule) }
            ))
        }
    }
    
    // MARK: - Storage Section
    
    private var storageSection: some View {
        Section {
            HStack {
                Text("Clipboard Items")
                Spacer()
                Text("\(viewModel.totalItemCount)")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Pinboards")
                Spacer()
                Text("\(viewModel.totalPinboardCount)")
                    .foregroundStyle(.secondary)
            }
            
            Picker("Keep History", selection: $viewModel.historyRetention) {
                ForEach(HistoryRetention.allCases) { retention in
                    Text(retention.displayName).tag(retention)
                }
            }
            
            Button("Clear All History", role: .destructive) {
                showingClearConfirmation = true
            }
        } header: {
            Text("Storage")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(viewModel.fullVersion)
                    .foregroundStyle(.secondary)
            }
            
            Button("Reset Settings") {
                showingResetConfirmation = true
            }
            
            Link(destination: URL(string: "https://example.com/privacy")!) {
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Link(destination: URL(string: "https://example.com/terms")!) {
                HStack {
                    Text("Terms of Service")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Add Rule Sheet
    
    private var addRuleSheet: some View {
        NavigationStack {
            Form {
                Section("Rule Details") {
                    TextField("Rule Name", text: $newRuleName)
                    
                    TextField("Pattern (Regex)", text: $newRulePattern)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                    
                    Picker("Action", selection: $newRuleAction) {
                        ForEach(RuleAction.allCases) { action in
                            Label(action.displayName, systemImage: action.icon)
                                .tag(action)
                        }
                    }
                }
                
                Section {
                    if !newRulePattern.isEmpty {
                        HStack {
                            Text("Pattern Valid")
                            Spacer()
                            Image(systemName: viewModel.validatePattern(newRulePattern) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(viewModel.validatePattern(newRulePattern) ? .green : .red)
                        }
                    }
                } header: {
                    Text("Validation")
                }
            }
            .navigationTitle("New Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showingAddRule = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        viewModel.addRule(
                            name: newRuleName,
                            pattern: newRulePattern,
                            action: newRuleAction
                        )
                        showingAddRule = false
                    }
                    .fontWeight(.semibold)
                    .disabled(newRuleName.isEmpty || !viewModel.validatePattern(newRulePattern))
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func resetRuleSheet() {
        newRuleName = ""
        newRulePattern = ""
        newRuleAction = .ignore
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel())
    }
}
