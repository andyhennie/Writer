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
    
    init(content: String = "") {
        self.content = content
    }
}
