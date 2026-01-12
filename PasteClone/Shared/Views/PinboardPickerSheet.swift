//
//  PinboardPickerSheet.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI

/// Sheet for selecting pinboards - Paste app style
struct PinboardPickerSheet: View {
    @Binding var selectedPinboard: Pinboard?
    @Bindable var viewModel: PinboardViewModel
    @Binding var isPresented: Bool
    @State private var showingCreateSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pinboard list
                ScrollView {
                    VStack(spacing: 4) {
                        // Clipboard (History) option
                        PinboardRowItem(
                            icon: "clock.arrow.circlepath",
                            iconColor: nil,
                            name: "Clipboard",
                            isSelected: selectedPinboard == nil,
                            onTap: {
                                selectedPinboard = nil
                                isPresented = false
                            },
                            onMenu: nil
                        )
                        
                        // User pinboards
                        ForEach(viewModel.pinboards) { pinboard in
                            PinboardRowItem(
                                icon: nil,
                                iconColor: pinboard.displayColor,
                                name: pinboard.name,
                                isSelected: selectedPinboard?.id == pinboard.id,
                                onTap: {
                                    selectedPinboard = pinboard
                                    isPresented = false
                                },
                                onMenu: {
                                    // Return menu content
                                }
                            )
                            .contextMenu {
                                Button {
                                    // Edit action
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    viewModel.deletePinboard(pinboard)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Pinboards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreatePinboardSheet(viewModel: viewModel)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
    }
}

/// Individual pinboard row item
struct PinboardRowItem: View {
    let icon: String?
    let iconColor: Color?
    let name: String
    let isSelected: Bool
    let onTap: () -> Void
    let onMenu: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon or color dot
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                } else if let color = iconColor {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                        .frame(width: 24)
                }
                
                // Name
                Text(name)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Menu button
                if onMenu != nil {
                    Menu {
                        Button {
                            // Edit
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            // Delete
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(.systemGray5) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Sheet for creating new pinboard
struct CreatePinboardSheet: View {
    @Bindable var viewModel: PinboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "pin.fill"
    
    private let colors = ["red", "orange", "yellow", "green", "blue", "purple", "pink"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(colorForName(color))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                        .padding(-4)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Pinboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        guard !name.isEmpty else { return }
                        viewModel.createPinboard(
                            name: name,
                            icon: selectedIcon,
                            color: selectedColor
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func colorForName(_ name: String) -> Color {
        switch name {
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
}

#Preview {
    PinboardPickerSheet(
        selectedPinboard: .constant(nil),
        viewModel: PinboardViewModel(),
        isPresented: .constant(true)
    )
}
