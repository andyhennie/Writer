//
//  DocumentContentView.swift
//  Writer
//
//  Created by Andreas Hennie on 03/07/2025.
//

import SwiftUI
import AppKit

struct DocumentContentView: View {
    @State var document: TextDocument
    @State private var isTitleBarHidden = false
    @State private var hoverRevealed = false
    @State private var mouseMonitor: Any?
    @State private var keyMonitor: Any?
    @State private var keyGlobalMonitor: Any?
    @State private var fontSize: CGFloat = NSFont.systemFontSize
    
    private let hoverTriggerBand: CGFloat = 50
    
    var body: some View {
        PaddedTextEditor(
            text: Binding(
                get: { document.content },
                set: { newValue in
                    document.content = newValue
                    document.isModified = true
                    updateWindowTitle()
                }
            ),
            font: .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor).ignoresSafeArea())
        .onAppear {
            if let window = NSApplication.shared.keyWindow {
                window.title = document.displayName
                WindowController.shared.configure(window: window, titleBarHidden: isTitleBarHidden)
            }
            installEventMonitors()
            
            NotificationCenter.default.addObserver(
                forName: .toggleTitleBar,
                object: nil,
                queue: .main
            ) { _ in
                toggleTitleBar()
            }
        }
        .onDisappear {
            removeEventMonitors()
            NotificationCenter.default.removeObserver(self, name: .toggleTitleBar, object: nil)
        }
    }
    
    private func updateWindowTitle() {
        guard let window = NSApplication.shared.keyWindow else { return }
        window.title = document.displayName
    }
    
    private func increaseFontSize() {
        fontSize = min(fontSize + 2, 48)
    }
    
    private func decreaseFontSize() {
        fontSize = max(fontSize - 2, 8)
    }
    
    private func toggleTitleBar() {
        guard let window = NSApplication.shared.keyWindow else { return }
        
        let previousResponder = window.firstResponder

        isTitleBarHidden.toggle()
        TitleBarState.shared.isHidden = isTitleBarHidden
        WindowController.shared.setTitleBar(hidden: isTitleBarHidden, for: window)
        hoverRevealed = false

        if let responder = previousResponder {
            window.makeFirstResponder(responder)
        }
    }
    
    private func installEventMonitors() {
        removeEventMonitors()

        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [self] event in
            handleMouseMove(event)
            return event
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            return handleKeyDown(event)
        }

        keyGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [self] event in
            _ = handleKeyDown(event)
        }
    }

    private func removeEventMonitors() {
        if let monitor = mouseMonitor { NSEvent.removeMonitor(monitor); mouseMonitor = nil }
        if let monitor = keyMonitor { NSEvent.removeMonitor(monitor); keyMonitor = nil }
        if let monitor = keyGlobalMonitor { NSEvent.removeMonitor(monitor); keyGlobalMonitor = nil }
    }

    private func handleMouseMove(_ event: NSEvent) {
        guard isTitleBarHidden, !hoverRevealed,
              let window = NSApplication.shared.keyWindow,
              event.window === window else { return }

        let y = event.locationInWindow.y
        let contentHeight = window.contentView?.bounds.height ?? 0
        let triggerBandStart = contentHeight - hoverTriggerBand

        if y >= triggerBandStart {
            WindowController.shared.setTitleBar(hidden: false, for: window)
            hoverRevealed = true
        }
    }

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        if event.modifierFlags.contains(.command) {
            if event.charactersIgnoringModifiers == "=" || event.charactersIgnoringModifiers == "+" {
                increaseFontSize()
                return nil
            } else if event.charactersIgnoringModifiers == "-" {
                decreaseFontSize()
                return nil
            }
        }
        
        guard isTitleBarHidden, let window = NSApplication.shared.keyWindow else { return event }

        if window.titleVisibility == .visible {
            WindowController.shared.setTitleBar(hidden: true, for: window)
            hoverRevealed = false
        }
        
        return event
    }
}