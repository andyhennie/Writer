//
//  DocumentManager.swift
//  Writer
//
//  Created by Andreas Hennie on 03/07/2025.
//

import Foundation
import SwiftUI
import AppKit

class DocumentManager: ObservableObject {
    static let shared = DocumentManager()
    
    @Published var documents: [TextDocument] = []
    
    private init() {}
    
    func createNewDocument() -> TextDocument {
        let document = TextDocument()
        documents.append(document)
        return document
    }
    
    func openDocument(at url: URL) throws -> TextDocument {
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let document = TextDocument(content: content, fileURL: url)
        document.isModified = false
        documents.append(document)
        return document
    }
    
    func saveDocument(_ document: TextDocument) throws {
        guard let url = document.fileURL else {
            throw DocumentError.noFileURL
        }
        
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        try document.content.write(to: url, atomically: true, encoding: .utf8)
        document.isModified = false
        document.lastModified = Date()
    }
    
    func saveDocumentAs(_ document: TextDocument, to url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        try document.content.write(to: url, atomically: true, encoding: .utf8)
        document.fileURL = url
        document.isModified = false
        document.lastModified = Date()
    }
    
    func presentSavePanel(for document: TextDocument) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = document.fileName
        panel.title = "Save"
        panel.message = "Choose where to save your document"
        
        if panel.runModal() == .OK {
            return panel.url
        }
        return nil
    }
    
    func presentOpenPanel() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.title = "Open"
        panel.message = "Choose a text file to open"
        
        if panel.runModal() == .OK {
            return panel.urls.first
        }
        return nil
    }
    
    func removeDocument(_ document: TextDocument) {
        documents.removeAll { $0 === document }
    }
}

enum DocumentError: Error {
    case noFileURL
    case accessDenied
    case fileNotFound
    case encodingError
    
    var localizedDescription: String {
        switch self {
        case .noFileURL:
            return "No file URL specified"
        case .accessDenied:
            return "Access to file denied"
        case .fileNotFound:
            return "File not found"
        case .encodingError:
            return "File encoding error"
        }
    }
}