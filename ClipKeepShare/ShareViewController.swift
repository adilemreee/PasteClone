//
//  ShareViewController.swift
//  ClipKeepShareExtension
//
//  Created for ClipKeep - Clipboard Manager Share Extension
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// Share extension view controller for receiving content from other apps
class ShareViewController: UIViewController {
    
    private var hostingController: UIHostingController<ShareExtensionView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        processSharedContent()
    }
    
    private func setupView() {
        let shareView = ShareExtensionView(
            onSave: { [weak self] pinboardId in
                self?.saveContent(to: pinboardId)
            },
            onCancel: { [weak self] in
                self?.cancel()
            }
        )
        
        let hostingController = UIHostingController(rootView: shareView)
        self.hostingController = hostingController
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func processSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return
        }
        
        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            
            for attachment in attachments {
                // Handle text
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] data, error in
                        if let text = data as? String {
                            DispatchQueue.main.async {
                                self?.handleText(text)
                            }
                        }
                    }
                }
                
                // Handle URL
                else if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, error in
                        if let url = data as? URL {
                            DispatchQueue.main.async {
                                self?.handleURL(url)
                            }
                        }
                    }
                }
                
                // Handle image
                else if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] data, error in
                        var image: UIImage?
                        
                        if let url = data as? URL {
                            image = UIImage(contentsOfFile: url.path)
                        } else if let imageData = data as? Data {
                            image = UIImage(data: imageData)
                        } else if let uiImage = data as? UIImage {
                            image = uiImage
                        }
                        
                        if let image = image {
                            DispatchQueue.main.async {
                                self?.handleImage(image)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var pendingItem: ClipboardItem?
    
    private func handleText(_ text: String) {
        // Check if it's a URL
        if let url = URL(string: text), url.scheme != nil {
            pendingItem = ClipboardItem.link(text)
        } else {
            pendingItem = ClipboardItem.text(text)
        }
        updateView()
    }
    
    private func handleURL(_ url: URL) {
        pendingItem = ClipboardItem.link(url.absoluteString)
        updateView()
    }
    
    private func handleImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let thumbnailSize = CGSize(width: 200, height: 200)
        let thumbnail = image.preparingThumbnail(of: thumbnailSize)
        let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.6)
        
        pendingItem = ClipboardItem.image(data: imageData, thumbnail: thumbnailData)
        updateView()
    }
    
    private func updateView() {
        if let item = pendingItem {
            hostingController?.rootView = ShareExtensionView(
                item: item,
                onSave: { [weak self] pinboardId in
                    self?.saveContent(to: pinboardId)
                },
                onCancel: { [weak self] in
                    self?.cancel()
                }
            )
        }
    }
    
    private func saveContent(to pinboardId: UUID?) {
        guard let item = pendingItem else {
            complete()
            return
        }
        
        // Save to shared storage
        let defaults = UserDefaults(suiteName: "group.adilemre.clipkeep")
        
        // Load existing items
        var items: [ClipboardItem] = []
        if let data = defaults?.data(forKey: "clipboardItems"),
           let existing = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = existing
        }
        
        // Add new item (optionally to pinboard)
        var newItem = item
        if let pinboardId = pinboardId {
            newItem.pinboardIds.append(pinboardId)
            newItem.isPinned = true
        }
        
        items.insert(newItem, at: 0)
        
        // Save back
        if let data = try? JSONEncoder().encode(items) {
            defaults?.set(data, forKey: "clipboardItems")
        }
        
        complete()
    }
    
    private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "ClipKeep", code: 0, userInfo: nil))
    }
    
    private func complete() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}

// MARK: - Share Extension SwiftUI View

struct ShareExtensionView: View {
    var item: ClipboardItem?
    var onSave: (UUID?) -> Void
    var onCancel: () -> Void
    
    @State private var selectedPinboard: UUID?
    @State private var pinboards: [Pinboard] = []
    
    init(
        item: ClipboardItem? = nil,
        onSave: @escaping (UUID?) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.item = item
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let item = item {
                    Section("Content") {
                        HStack {
                            Image(systemName: item.type.icon)
                                .foregroundStyle(item.type.color)
                            Text(item.previewText ?? "Item")
                                .lineLimit(3)
                        }
                    }
                    
                    Section("Save to Pinboard") {
                        Button("Clipboard History Only") {
                            selectedPinboard = nil
                        }
                        .foregroundStyle(selectedPinboard == nil ? Color.accentColor : Color.primary)
                        
                        ForEach(pinboards) { pinboard in
                            Button {
                                selectedPinboard = pinboard.id
                            } label: {
                                HStack {
                                    Image(systemName: pinboard.iconName)
                                        .foregroundStyle(pinboard.displayColor)
                                    Text(pinboard.name)
                                    Spacer()
                                    if selectedPinboard == pinboard.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                } else {
                    Section {
                        ProgressView("Loading...")
                    }
                }
            }
            .navigationTitle("Save to ClipKeep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(selectedPinboard)
                    }
                    .fontWeight(.semibold)
                    .disabled(item == nil)
                }
            }
        }
        .onAppear {
            loadPinboards()
        }
    }
    
    private func loadPinboards() {
        let defaults = UserDefaults(suiteName: "group.adilemre.clipkeep")
        if let data = defaults?.data(forKey: "pinboards"),
           let boards = try? JSONDecoder().decode([Pinboard].self, from: data) {
            pinboards = boards.sorted { $0.sortOrder < $1.sortOrder }
        }
    }
}

#Preview {
    ShareExtensionView(
        item: .sampleText,
        onSave: { _ in },
        onCancel: {}
    )
}
