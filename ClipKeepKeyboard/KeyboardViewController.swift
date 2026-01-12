//
//  KeyboardViewController.swift
//  ClipboardKeyboard
//
//  Created for ClipKeep - Clipboard Manager Keyboard Extension
//

import UIKit
import SwiftUI

/// Main view controller for the keyboard extension
class KeyboardViewController: UIInputViewController {
    
    private var hostingController: UIHostingController<KeyboardView>?
    private var dataProvider = KeyboardDataProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🎹 KeyboardViewController: viewDidLoad called")
        
        // Check if full access is granted
        let hasFullAccess = hasFullAccess
        print("🎹 KeyboardViewController: Full Access = \(hasFullAccess)")
        
        setupKeyboardView()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Update constraints if needed
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("🎹 KeyboardViewController: viewDidAppear called")
        print("🎹 View frame: \(view.frame)")
    }
    
    private func setupKeyboardView() {
        // Create the SwiftUI keyboard view
        let keyboardView = KeyboardView(
            dataProvider: dataProvider,
            onItemSelected: { [weak self] item in
                self?.insertText(item)
            },
            onNextKeyboard: { [weak self] in
                self?.advanceToNextInputMode()
            },
            onSpace: { [weak self] in
                self?.textDocumentProxy.insertText(" ")
                self?.playHaptic()
            },
            onDelete: { [weak self] in
                self?.textDocumentProxy.deleteBackward()
                self?.playHaptic()
            },
            onReturn: { [weak self] in
                self?.textDocumentProxy.insertText("\n")
                self?.playHaptic()
            }
        )
        
        // Create hosting controller
        let hostingController = UIHostingController(rootView: keyboardView)
        self.hostingController = hostingController
        
        // Make ALL backgrounds transparent for true glass effect
        view.backgroundColor = .clear
        hostingController.view.backgroundColor = .clear
        inputView?.backgroundColor = .clear
        
        // Remove any default keyboard background
        if let inputView = inputView {
            inputView.allowsSelfSizing = true
        }
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Set preferred height (iOS 26 native style)
        view.heightAnchor.constraint(equalToConstant: 300).isActive = true
    }
    
    private func insertText(_ item: ClipboardItem) {
        switch item.type {
        case .text, .link:
            textDocumentProxy.insertText(item.rawData)
        case .image:
            // Images cannot be inserted via keyboard, show hint
            textDocumentProxy.insertText("[Image from ClipKeep]")
        case .file:
            textDocumentProxy.insertText(item.fileName ?? item.rawData)
        }
        
        // Haptic feedback
        playHaptic()
    }
    
    private func playHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // Called when text is about to change
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // Called when text has changed
    }
}
