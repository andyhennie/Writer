//
//  CUPSPrintManager.swift
//  Writer
//
//  Created by Andreas Hennie on 02/07/2025.
//

import AppKit
import Foundation

class CUPSPrintManager {
    static let shared = CUPSPrintManager()
    
    private init() {}
    
    func printTodosNatively(from text: String) throws {
        // Split text into non-empty lines
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw NativePrintError.noContent
        }
        
        // Generate ESC/POS data
        let escPosData = ESCPOSGenerator.generateESCPOSData(for: lines)
        
        // Print using CUPS
        let printerName = try findEpsonPrinter()
        try printRawData(escPosData, printerName: printerName)
    }
    
    private func findEpsonPrinter() throws -> String {
        // Check CUPS printer list
        let cupsProcess = Process()
        cupsProcess.executableURL = URL(fileURLWithPath: "/usr/bin/lpstat")
        cupsProcess.arguments = ["-p"]
        
        let cupsPipe = Pipe()
        cupsProcess.standardOutput = cupsPipe
        cupsProcess.standardError = cupsPipe
        
        do {
            try cupsProcess.run()
            cupsProcess.waitUntilExit()
            
            let cupsOutput = cupsPipe.fileHandleForReading.readDataToEndOfFile()
            let cupsString = String(data: cupsOutput, encoding: .utf8) ?? ""
            
            // Parse CUPS output to find EPSON printer
            let lines = cupsString.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("EPSON") && line.contains("TM") {
                    let components = line.components(separatedBy: " ")
                    if components.count >= 2 {
                        return components[1]
                    }
                }
            }
        } catch {
            // Continue to fallback
        }
        
        // Fallback: check NSPrinter names and convert to CUPS names
        let availablePrinters = NSPrinter.printerNames
        for printerName in availablePrinters {
            if printerName.uppercased().contains("EPSON") || printerName.uppercased().contains("TM") {
                // Convert display name to CUPS name (spaces to underscores)
                return printerName.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_")
            }
        }
        
        throw NativePrintError.printerNotFound("EPSON thermal printer")
    }
    
    private func printRawData(_ data: Data, printerName: String) throws {
        try printRawDataViaCUPS(data, printerName: printerName)
    }
    
    private func printRawDataViaCUPS(_ data: Data, printerName: String) throws {
        // Use lpr command to send raw data to printer via stdin
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/lpr")
        process.arguments = ["-P", printerName, "-o", "raw", "-"]
        
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = environment
        
        let outputPipe = Pipe()
        let inputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.standardInput = inputPipe
        
        try process.run()
        
        // Send data via stdin
        inputPipe.fileHandleForWriting.write(data)
        inputPipe.fileHandleForWriting.closeFile()
        
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let output = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let _ = String(data: output, encoding: .utf8) ?? ""
            throw NativePrintError.printOperationFailed
        }
    }
}


enum NativePrintError: LocalizedError {
    case noContent
    case printerNotFound(String)
    case printOperationFailed
    
    var errorDescription: String? {
        switch self {
        case .noContent:
            return "No content to print"
        case .printerNotFound(let name):
            return "Printer '\(name)' not found"
        case .printOperationFailed:
            return "Print operation failed"
        }
    }
}