//
//  Item.swift
//  Writer
//
//  Created by Andreas Hennie on 02/07/2025.
//

import Foundation
import SwiftData

@Model
final class TextDocument {
    var content: String
    var fileURL: URL?
    var isModified: Bool = false
    var lastModified: Date = Date()
    
    init(content: String = "", fileURL: URL? = nil) {
        self.content = content
        self.fileURL = fileURL
        self.lastModified = Date()
    }
    
    var fileName: String {
        if let url = fileURL {
            return url.lastPathComponent
        }
        return "Untitled"
    }
    
    var displayName: String {
        let name = fileName
        if fileURL == nil && content.isEmpty {
            return name
        }
        return isModified ? "\(name) •" : name
    }
}
