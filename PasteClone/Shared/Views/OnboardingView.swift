//
//  OnboardingView.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI

/// Onboarding flow for first-time users
struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var hasCompletedOnboarding: Bool
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to ClipKeep",
            subtitle: "Your intelligent clipboard manager",
            description: "Never lose anything you copy. ClipKeep automatically saves everything to your clipboard history.",
            icon: "clipboard.fill",
            color: .blue
        ),
        OnboardingPage(
            title: "Unlimited History",
            subtitle: "Save everything you copy",
            description: "Text, images, links, and files are all saved automatically. Search and find anything in seconds.",
            icon: "clock.fill",
            color: .purple
        ),
        OnboardingPage(
            title: "Organize with Pinboards",
            subtitle: "Keep your favorites handy",
            description: "Create pinboards to organize frequently used items. Perfect for code snippets, addresses, or quick replies.",
            icon: "pin.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "Secure & Private",
            subtitle: "Your data stays yours",
            description: "All data is stored locally and synced through your private iCloud. Define rules to automatically ignore sensitive information.",
            icon: "lock.shield.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Access Anywhere",
            subtitle: "Keyboard extension included",
            description: "Use the ClipKeep keyboard to paste items quickly in any app. Sync across all your devices with iCloud.",
            icon: "keyboard.fill",
            color: .teal
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Page indicators and buttons
            VStack(spacing: 24) {
                // Page dots
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                
                // Buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button("Continue") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Get Started") {
                            completeOnboarding()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [
                    pages[currentPage].color.opacity(0.1),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut, value: currentPage)
        )
    }
    
    // MARK: - Page View
    
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 140, height: 140)
                
                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(page.color)
            }
            
            // Text content
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
        UserSettings.shared.hasCompletedOnboarding = true
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
