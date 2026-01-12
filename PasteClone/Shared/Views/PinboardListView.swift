//
//  PinboardListView.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI

/// List/grid view of all pinboards
struct PinboardListView: View {
    @Bindable var viewModel: PinboardViewModel
    @State private var showingCreateSheet = false
    @State private var newPinboardName = ""
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "pin.fill"
    @State private var editingPinboard: Pinboard?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        Group {
            if viewModel.pinboards.isEmpty {
                emptyStateView
            } else {
                gridView
            }
        }
        .navigationTitle("Pinboards")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    resetCreateSheet()
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            createPinboardSheet
        }
        .sheet(item: $editingPinboard) { pinboard in
            editPinboardSheet(pinboard)
        }
        .refreshable {
            viewModel.refresh()
        }
    }
    
    // MARK: - Grid View
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.pinboards) { pinboard in
                    NavigationLink {
                        PinboardDetailView(pinboard: pinboard, viewModel: viewModel)
                    } label: {
                        pinboardCard(pinboard)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            editingPinboard = pinboard
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        if pinboard.isShared {
                            Button {
                                viewModel.stopSharing(pinboard)
                            } label: {
                                Label("Stop Sharing", systemImage: "person.badge.minus")
                            }
                        } else {
                            Button {
                                Task {
                                    await viewModel.sharePinboard(pinboard)
                                }
                            } label: {
                                Label("Share", systemImage: "person.badge.plus")
                            }
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            viewModel.deletePinboard(pinboard)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Pinboard Card
    
    private func pinboardCard(_ pinboard: Pinboard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(pinboard.displayColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: pinboard.iconName)
                        .font(.title3)
                        .foregroundStyle(pinboard.displayColor)
                }
                
                Spacer()
                
                if pinboard.isShared {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pinboard.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(pinboard.itemCount) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Pinboards", systemImage: "pin.slash")
        } description: {
            Text("Create pinboards to organize your frequently used items.")
        } actions: {
            Button("Create Pinboard") {
                resetCreateSheet()
                showingCreateSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Create Sheet
    
    private var createPinboardSheet: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Pinboard Name", text: $newPinboardName)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(Pinboard.availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(Pinboard.availableColors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(colorFor(color))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("New Pinboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showingCreateSheet = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        viewModel.createPinboard(
                            name: newPinboardName,
                            icon: selectedIcon,
                            color: selectedColor
                        )
                        showingCreateSheet = false
                    }
                    .fontWeight(.semibold)
                    .disabled(newPinboardName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Edit Sheet
    
    private func editPinboardSheet(_ pinboard: Pinboard) -> some View {
        EditPinboardSheet(
            pinboard: $editingPinboard,
            onSave: { updated in
                viewModel.updatePinboard(id: updated.id, name: updated.name, icon: updated.iconName, color: updated.color)
            }
        )
    }
    
    // MARK: - Helpers
    
    private func resetCreateSheet() {
        newPinboardName = ""
        selectedColor = "blue"
        selectedIcon = "pin.fill"
    }
    
    private func colorFor(_ name: String) -> Color {
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

// MARK: - Edit Pinboard Sheet

struct EditPinboardSheet: View {
    @Binding var pinboard: Pinboard?
    var onSave: (Pinboard) -> Void
    
    @State private var name: String = ""
    @State private var iconName: String = "pin.fill"
    @State private var color: String = "blue"
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Pinboard Name", text: $name)
                }
                
                Section("Icon") {
                    iconPicker
                }
                
                Section("Color") {
                    colorPicker
                }
            }
            .navigationTitle("Edit Pinboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        pinboard = nil
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if var updated = pinboard {
                            updated.name = name
                            updated.iconName = iconName
                            updated.color = color
                            onSave(updated)
                        }
                        pinboard = nil
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            if let p = pinboard {
                name = p.name
                iconName = p.iconName
                color = p.color
            }
        }
    }
    
    private var iconPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
            ForEach(Pinboard.availableIcons, id: \.self) { icon in
                Button {
                    iconName = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(iconName == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var colorPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
            ForEach(Pinboard.availableColors, id: \.self) { c in
                Button {
                    color = c
                } label: {
                    Circle()
                        .fill(colorValue(for: c))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(color == c ? Color.primary : Color.clear, lineWidth: 3)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func colorValue(for name: String) -> Color {
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
    NavigationStack {
        PinboardListView(viewModel: PinboardViewModel())
    }
}
