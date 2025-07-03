//
//  ESCPOSGenerator.swift
//  Writer
//
//  Created by Andreas Hennie on 02/07/2025.
//

import Foundation

class ESCPOSGenerator {
    
    // ESC/POS Commands (from original script)
    private static let RESET_CMD = Data([0x1B, 0x40])        // Initialize printer (reset settings)
    private static let CHARSET_CMD = Data([0x1B, 0x74, 0x05]) // Set character set to CP865 (Nordic)
    private static let SPACING_CMD = Data([0x1B, 0x20, 0x01]) // Set character spacing to 1 dot
    private static let FONT_CMD = Data([0x1B, 0x21, 0x38])   // Set font to double width + double height + bold
    private static let CUT_CMD = Data([0x1D, 0x56, 0x41])    // Partial cut (leave small connecting strip)
    private static let LINE_FEED = Data([0x0A])              // Line feed
    
    // Configuration (from original script)
    private static let LINES_BEFORE = 6
    private static let LINES_AFTER = 10
    private static let TEXT_WIDTH = 20
    
    static func generateESCPOSData(for lines: [String]) -> Data {
        var data = Data()
        
        // Initialize printer
        data.append(RESET_CMD)
        data.append(CHARSET_CMD)
        data.append(SPACING_CMD)
        
        for line in lines {
            // Skip empty lines
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            
            // Add spacing before text
            for _ in 0..<LINES_BEFORE {
                data.append(LINE_FEED)
            }
            
            // Format and add the todo text
            let formattedText = formatText(trimmedLine)
            data.append(FONT_CMD)
            
            if let textData = formattedText.data(using: .isoLatin1) {
                data.append(textData)
            } else if let fallbackData = formattedText.data(using: .utf8) {
                data.append(fallbackData)
            }
            
            // Add spacing after text and cut
            for _ in 0..<LINES_AFTER {
                data.append(LINE_FEED)
            }
            data.append(CUT_CMD)
            data.append(LINE_FEED)
            data.append(LINE_FEED)
        }
        
        
        return data
    }
    
    private static func formatText(_ text: String) -> String {
        // Capitalize first letter (from original script)
        let firstChar = String(text.prefix(1)).uppercased()
        let restChars = String(text.dropFirst())
        let capitalized = firstChar + restChars
        
        // Convert Norwegian characters to CP865 compatible
        let cp865Compatible = convertToCP865Compatible(capitalized)
        
        // Word wrap at specified width (from original script)
        return wrapText(cp865Compatible, width: TEXT_WIDTH)
    }
    
    private static func convertToCP865Compatible(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "æ", with: "\u{91}")  // CP865 code for æ
            .replacingOccurrences(of: "Æ", with: "\u{92}")  // CP865 code for Æ
            .replacingOccurrences(of: "ø", with: "\u{9B}")  // CP865 code for ø
            .replacingOccurrences(of: "Ø", with: "\u{9D}")  // CP865 code for Ø
            .replacingOccurrences(of: "å", with: "\u{86}")  // CP865 code for å
            .replacingOccurrences(of: "Å", with: "\u{8F}")  // CP865 code for Å
    }
    
    private static func wrapText(_ text: String, width: Int) -> String {
        let words = text.components(separatedBy: .whitespaces)
        var lines: [String] = []
        var currentLine = ""
        
        for word in words {
            let testLine = currentLine.isEmpty ? word : currentLine + " " + word
            
            if testLine.count <= width {
                currentLine = testLine
            } else {
                if !currentLine.isEmpty {
                    lines.append(currentLine)
                }
                currentLine = word
            }
        }
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        return lines.joined(separator: "\n")
    }
}