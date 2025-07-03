//
//  ContentView.swift
//  Writer
//
//  Created by Andreas Hennie on 02/07/2025.
//

import SwiftUI
import SwiftData
import AppKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var documents: [TextDocument]
    @State private var isTitleBarHidden = false
    @State private var hoverRevealed = false
    @State private var mouseMonitor: Any?
    @State private var keyMonitor: Any?
    @State private var keyGlobalMonitor: Any?
    
    private let hoverTriggerBand: CGFloat = 50   // Size of the hover zone at top (px)
    
    private var document: TextDocument {
        if documents.isEmpty {
            let newDoc = TextDocument()
            modelContext.insert(newDoc)
            return newDoc
        }
        return documents.first!
    }

    var body: some View {
        PaddedTextEditor(
            text: Binding(
                get: { document.content },
                set: { document.content = $0 }
            ),
            font: .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor).ignoresSafeArea())
        .onAppear {
            if let window = NSApplication.shared.keyWindow {
                WindowController.shared.configure(window: window, titleBarHidden: isTitleBarHidden)
            }
            installEventMonitors()
            
            // Listen for menu toggle notifications
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
            handleKeyDown(event)
            return event
        }

        keyGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [self] event in
            handleKeyDown(event)
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

    private func handleKeyDown(_ event: NSEvent) {
        guard isTitleBarHidden, let window = NSApplication.shared.keyWindow else { return }

        // Only act if title bar currently visible (hover reveal)
        if window.titleVisibility == .visible {
            WindowController.shared.setTitleBar(hidden: true, for: window)
            hoverRevealed = false
        }
    }
}

struct PaddedTextEditor: NSViewRepresentable {
    @Binding var text: String
    let font: NSFont
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // Configure text view
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = font
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.systemBlue
        
        // Set text container insets for padding (top, left, right - no bottom)
        textView.textContainerInset = NSSize(width: 32, height: 32) // Left/right: 32pt, top/bottom: 32pt each
        textView.textContainer?.lineFragmentPadding = 0
        
        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        scrollView.scrollerStyle = .overlay     // Scroller overlays to reach top edge
        
        // Set delegate
        textView.delegate = context.coordinator
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: PaddedTextEditor
        
        init(_ parent: PaddedTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                parent.text = textView.string
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TextDocument.self, inMemory: true)
}

// MARK: - Conditional view modifier helper

extension View {
    @ViewBuilder
    fileprivate func applyIf<Content: View>(_ condition: Bool,
                                           transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

