//
//  DetailView.swift
//  PasteClone
//
//  Created for ClipKeep - Clipboard Manager
//

import SwiftUI
import UIKit

/// Full detail view for a clipboard item
struct DetailView: View {
    let item: ClipboardItem
    @Bindable var viewModel: ClipboardListViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedText: String = ""
    @State private var isEditing = false
    @State private var showingPinboardPicker = false
    @State private var showingShareSheet = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with type info
                headerView
                
                Divider()
                
                // Main content
                contentView
                
                Divider()
                
                // Metadata
                metadataView
                
                // Tags
                if !item.tags.isEmpty {
                    tagsView
                }
                
                // Pinboards
                if !item.pinboardIds.isEmpty {
                    pinboardsView
                }
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: copyItem) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    
                    Button {
                        showingPinboardPicker = true
                    } label: {
                        Label("Add to Pinboard", systemImage: "pin")
                    }
                    
                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    if item.type == .text {
                        Button {
                            editedText = item.rawData
                            isEditing = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingPinboardPicker) {
            pinboardPickerSheet
        }
        .sheet(isPresented: $isEditing) {
            textEditorSheet
        }
        .sheet(isPresented: $showingShareSheet) {
            if let items = shareItems {
                ShareSheet(items: items)
            }
        }
        .confirmationDialog(
            "Delete Item?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.delete(item)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.type.color.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: item.type.icon)
                    .font(.title2)
                    .foregroundStyle(item.type.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.type.displayName)
                    .font(.headline)
                
                Text(item.fullFormattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.orange)
            }
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        switch item.type {
        case .text:
            textContentView
            
        case .link:
            linkContentView
            
        case .image:
            imageContentView
            
        case .file:
            fileContentView
        }
    }
    
    private var textContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content")
                .font(.headline)
            
            Text(item.rawData)
                .font(.body)
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Character count
            Text("\(item.rawData.count) characters")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var linkContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Link")
                .font(.headline)
            
            if let title = item.linkTitle {
                Text(title)
                    .font(.body.weight(.medium))
            }
            
            Link(destination: URL(string: item.rawData) ?? URL(string: "about:blank")!) {
                HStack {
                    Image(systemName: "link")
                    Text(item.rawData)
                        .lineLimit(2)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var imageContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image")
                .font(.headline)
            
            if let data = Data(base64Encoded: item.rawData),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Image info
                Text("\(Int(uiImage.size.width)) × \(Int(uiImage.size.height)) pixels")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var fileContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("File")
                .font(.headline)
            
            HStack {
                Image(systemName: "doc.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading) {
                    Text(item.fileName ?? "Unknown")
                        .font(.body.weight(.medium))
                    
                    if let url = item.url {
                        Text(url.pathExtension.uppercased())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Metadata
    
    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("Created")
                        .foregroundStyle(.secondary)
                    Text(item.fullFormattedDate)
                }
                
                if let sourceApp = item.sourceAppIdentifier {
                    GridRow {
                        Text("Source")
                            .foregroundStyle(.secondary)
                        Text(sourceApp)
                    }
                }
                
                GridRow {
                    Text("ID")
                        .foregroundStyle(.secondary)
                    Text(item.id.uuidString.prefix(8) + "...")
                        .font(.caption.monospaced())
                }
            }
            .font(.subheadline)
        }
    }
    
    // MARK: - Tags
    
    private var tagsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Pinboards
    
    private var pinboardsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pinboards")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(viewModel.availablePinboards.filter { item.pinboardIds.contains($0.id) }) { pinboard in
                    HStack(spacing: 4) {
                        Image(systemName: pinboard.iconName)
                        Text(pinboard.name)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(pinboard.displayColor.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Sheets
    
    private var pinboardPickerSheet: some View {
        NavigationStack {
            List(viewModel.availablePinboards) { pinboard in
                Button {
                    viewModel.pin(item, to: pinboard)
                    showingPinboardPicker = false
                } label: {
                    HStack {
                        Image(systemName: pinboard.iconName)
                            .foregroundStyle(pinboard.displayColor)
                        Text(pinboard.name)
                        Spacer()
                        if item.pinboardIds.contains(pinboard.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("Add to Pinboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingPinboardPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private var textEditorSheet: some View {
        NavigationStack {
            TextEditor(text: $editedText)
                .padding()
                .navigationTitle("Edit Text")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            isEditing = false
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            // Copy edited text to clipboard
                            UIPasteboard.general.string = editedText
                            isEditing = false
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
    }
    
    // MARK: - Actions
    
    private func copyItem() {
        viewModel.copyToClipboard(item)
    }
    
    private var shareItems: [Any]? {
        viewModel.shareItem(item).isEmpty ? nil : viewModel.shareItem(item)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(
            item: .sampleText,
            viewModel: ClipboardListViewModel()
        )
    }
}
