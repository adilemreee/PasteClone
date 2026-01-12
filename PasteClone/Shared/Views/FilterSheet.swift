//
//  FilterSheet.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI

/// Filter sheet - Paste app style
struct FilterSheet: View {
    @Binding var selectedTypes: Set<ClipboardItemType>
    @Binding var selectedDateFilter: DateFilter?
    @Binding var isPresented: Bool
    
    enum DateFilter: String, CaseIterable, Identifiable {
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This week"
        case lastWeek = "Last week"
        case last30Days = "Last 30 days"
        
        var id: String { rawValue }
        
        var icon: String { "calendar" }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Type section
                    filterSection(title: "Type") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            FilterChip(
                                icon: "link",
                                title: "Link",
                                isSelected: selectedTypes.contains(.link)
                            ) {
                                toggleType(.link)
                            }
                            
                            FilterChip(
                                icon: "text.alignleft",
                                title: "Text",
                                isSelected: selectedTypes.contains(.text)
                            ) {
                                toggleType(.text)
                            }
                            
                            FilterChip(
                                icon: "photo",
                                title: "Image",
                                isSelected: selectedTypes.contains(.image)
                            ) {
                                toggleType(.image)
                            }
                            
                            FilterChip(
                                icon: "doc",
                                title: "File",
                                isSelected: selectedTypes.contains(.file)
                            ) {
                                toggleType(.file)
                            }
                        }
                    }
                    
                    // App section (placeholder)
                    filterSection(title: "App") {
                        Text("All apps")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    
                    // Date section
                    filterSection(title: "Date") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(DateFilter.allCases) { filter in
                                FilterChip(
                                    icon: filter.icon,
                                    title: filter.rawValue,
                                    isSelected: selectedDateFilter == filter
                                ) {
                                    if selectedDateFilter == filter {
                                        selectedDateFilter = nil
                                    } else {
                                        selectedDateFilter = filter
                                    }
                                }
                            }
                        }
                    }
                    
                    // Device section
                    filterSection(title: "Device") {
                        FilterChip(
                            icon: "iphone",
                            title: "iPhone",
                            isSelected: true
                        ) {
                            // Device filter
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            content()
        }
    }
    
    private func toggleType(_ type: ClipboardItemType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }
}

/// Filter chip button
struct FilterChip: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                Text(title)
                    .font(.body)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FilterSheet(
        selectedTypes: .constant([]),
        selectedDateFilter: .constant(nil),
        isPresented: .constant(true)
    )
}
