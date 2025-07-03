//
//  FileCommands.swift
//  Writer
//
//  Created by Andreas Hennie on 03/07/2025.
//

import SwiftUI
import AppKit

struct FileCommands: Commands {
    @ObservedObject private var documentManager = DocumentManager.shared
    
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New") {
                createNewWindow()
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("Open...") {
                openDocument()
            }
            .keyboardShortcut("o", modifiers: .command)
        }
        
        CommandGroup(replacing: .saveItem) {
            Button("Save") {
                saveCurrentDocument()
            }
            .keyboardShortcut("s", modifiers: .command)
            
            Button("Save As...") {
                saveCurrentDocumentAs()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        }
        
        CommandGroup(replacing: .textEditing) {
            // Keep default text editing commands
        }
    }
    
    private func createNewWindow() {
        let document = documentManager.createNewDocument()
        openWindowForDocument(document)
    }
    
    private func openDocument() {
        guard let url = documentManager.presentOpenPanel() else { return }
        
        do {
            let document = try documentManager.openDocument(at: url)
            openWindowForDocument(document)
        } catch {
            presentError(error)
        }
    }
    
    private func saveCurrentDocument() {
        guard let document = getCurrentDocument() else { return }
        
        if document.fileURL == nil {
            saveCurrentDocumentAs()
            return
        }
        
        do {
            try documentManager.saveDocument(document)
            updateWindowTitle(for: document)
        } catch {
            presentError(error)
        }
    }
    
    private func saveCurrentDocumentAs() {
        guard let document = getCurrentDocument() else { return }
        guard let url = documentManager.presentSavePanel(for: document) else { return }
        
        do {
            try documentManager.saveDocumentAs(document, to: url)
            updateWindowTitle(for: document)
        } catch {
            presentError(error)
        }
    }
    
    private func getCurrentDocument() -> TextDocument? {
        guard NSApplication.shared.keyWindow != nil else { return nil }
        
        // Find the document associated with the current window
        // This is a simplified approach - in a real app you'd have a more robust way to track this
        return documentManager.documents.first
    }
    
    private func openWindowForDocument(_ document: TextDocument) {
        // Create a new window for the document
        let contentView = DocumentContentView(document: document)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = document.displayName
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        window.center()
        
        // Configure the window with our existing WindowController
        WindowController.shared.configure(window: window, titleBarHidden: false)
    }
    
    private func updateWindowTitle(for document: TextDocument) {
        guard let window = NSApplication.shared.keyWindow else { return }
        window.title = document.displayName
    }
    
    private func presentError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}