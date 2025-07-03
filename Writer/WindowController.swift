//
//  WindowController.swift
//  Writer
//
//  Created by Andreas Hennie on 03/07/2025.
//

import AppKit
import SwiftUI
import os.log

class WindowController: NSObject, NSWindowDelegate {
    static let shared = WindowController()
    
    private var isTitleBarHidden = false
    private var viewMonitor: Any?
    private var window: NSWindow?
    
    // Simple approach: just track what we hid
    private var hiddenViews: Set<NSView> = []
    
    // Logging
    private let logger = Logger(subsystem: "com.example.Writer", category: "WindowController")
    
    override private init() {
        super.init()
    }
    
    func configure(window: NSWindow, titleBarHidden: Bool) {
        logger.info("🔧 Configure window - titleBarHidden: \(titleBarHidden)")
        
        self.window = window
        window.delegate = self
        isTitleBarHidden = titleBarHidden
        
        // Core window setup - clean approach
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = titleBarHidden ? .hidden : .visible
        window.toolbar?.isVisible = !titleBarHidden
        window.isMovableByWindowBackground = true
        
        // The key fix: Disable title bar separator (macOS 12+)
        if #available(macOS 12.0, *) {
            window.titlebarSeparatorStyle = titleBarHidden ? .none : .automatic
        }
        
        logger.info("🔧 Window style configured - titleVisibility: \(window.titleVisibility.rawValue)")
        
        // Hide standard buttons
        for type in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(type)?.isHidden = titleBarHidden
        }
        
        if titleBarHidden {
            suppressTitleBarViews(in: window)
            startViewMonitoring()
        } else {
            restoreAllViews()
            stopViewMonitoring()
        }
        
        
        logger.info("🔧 Configure complete - isTitleBarHidden: \(self.isTitleBarHidden)")
    }
    
    
    private func suppressTitleBarViews(in window: NSWindow) {
        logger.info("🫥 Starting suppression")
        
        guard let contentView = window.contentView,
              let themeFrame = contentView.superview else {
            logger.error("❌ No content view or theme frame")
            return
        }
        
        logger.info("🔍 Theme frame has \(themeFrame.subviews.count) subviews")
        
        // Don't clear previous state - we might be re-suppressing
        suppressViewsRecursively(in: themeFrame, excluding: contentView)
        
        
        logger.info("🫥 Suppression complete - hiddenViews count: \(self.hiddenViews.count)")
    }
    
    
    
    private func suppressViewsRecursively(in parentView: NSView, excluding excludedView: NSView) {
        for (index, subview) in parentView.subviews.enumerated() {
            if subview === excludedView { 
                logger.debug("⏭️ Skipping content view at index \(index)")
                continue 
            }
            
            let className = String(describing: type(of: subview))
            let frame = subview.frame
            
            logger.debug("🔍 View[\(index)]: \(className) - frame: \(String(describing: frame)) - hidden: \(subview.isHidden) - alpha: \(subview.alphaValue)")
            
            // Target specific title bar view classes
            if shouldSuppressView(subview, className: className, parentView: parentView) {
                logger.info("🎯 Suppressing: \(className) - original frame: \(String(describing: frame))")
                
                // Only suppress if not already suppressed
                if !hiddenViews.contains(subview) {
                    hiddenViews.insert(subview)
                    subview.isHidden = true
                    logger.info("✅ Suppressed: \(className)")
                } else {
                    logger.debug("⚠️ Already suppressed: \(className)")
                }
            }
            
            // Recursively check subviews
            suppressViewsRecursively(in: subview, excluding: excludedView)
        }
    }
    
    private func shouldSuppressView(_ subview: NSView, className: String, parentView: NSView) -> Bool {
        // Target specific title bar view classes
        if className.contains("Titlebar") || 
           className.contains("NSTitlebar") ||
           className.contains("TitlebarContainer") {
            return true
        }
        
        // Visual effect views that look like title bars
        if className.contains("NSVisualEffectView") && 
           subview.frame.height < 50 && 
           subview.frame.maxY >= parentView.frame.height - 30 &&
           subview.frame.width > 100 {
            return true
        }
        
        // Plain NSView containers positioned at title bar location
        if className == "NSView" &&
           subview.frame.height <= 30 &&
           subview.frame.width > 100 &&
           subview.frame.maxY >= parentView.frame.height - 30 &&
           subview.frame.origin.x == 0 {
            logger.info("🎯 Found title bar NSView container: \(String(describing: subview.frame))")
            return true
        }
        
        return false
    }
    
    private func restoreAllViews() {
        logger.info("🔄 Starting restoration - hiddenViews count: \(self.hiddenViews.count)")
        
        for view in hiddenViews {
            let className = String(describing: type(of: view))
            logger.info("🔄 Restoring: \(className)")
            view.isHidden = false
        }
        
        hiddenViews.removeAll()
        logger.info("✅ Restoration complete - hiddenViews cleared")
    }
    
    private func startViewMonitoring() {
        logger.info("👁️ Starting view monitoring")
        guard let window = window else { return }
        
        viewMonitor = NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let view = notification.object as? NSView,
                  view.window === window,
                  self.isTitleBarHidden else { return }
            
            let className = String(describing: type(of: view))
            if className.contains("Titlebar") || 
               className.contains("NSVisualEffectView") ||
               (className == "NSView" && view.frame.height <= 30 && view.frame.width > 100) {
                self.logger.info("🚨 Detected recreated title bar view: \(className) - \(String(describing: view.frame))")
                // Immediate suppression - no delay
                self.suppressTitleBarViews(in: window)
            }
        }
    }
    
    private func stopViewMonitoring() {
        logger.info("👁️ Stopping view monitoring")
        if let monitor = viewMonitor {
            NotificationCenter.default.removeObserver(monitor)
            viewMonitor = nil
        }
    }
    
    func setTitleBar(hidden: Bool, for window: NSWindow) {
        logger.info("🎛️ setTitleBar called - hidden: \(hidden) - current state: \(self.isTitleBarHidden)")
        
        // Don't do anything if we're already in the correct state
        if isTitleBarHidden == hidden {
            logger.info("⏭️ Already in correct state, skipping")
            return
        }
        
        isTitleBarHidden = hidden
        
        // Apply core settings
        window.titlebarAppearsTransparent = hidden
        window.titleVisibility = hidden ? .hidden : .visible
        window.toolbar?.isVisible = !hidden
        
        // The key fix: Disable/restore separator (macOS 12+)
        if #available(macOS 12.0, *) {
            window.titlebarSeparatorStyle = hidden ? .none : .automatic
        }
        
        logger.info("🎛️ Basic settings applied - titleVisibility: \(window.titleVisibility.rawValue)")
        
        // Hide/show standard window buttons
        for type in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(type)?.isHidden = hidden
        }
        
        // Configure toolbar and view suppression
        if hidden {
            window.toolbarStyle = .unifiedCompact
            suppressTitleBarViews(in: window)
            startViewMonitoring()
        } else {
            window.toolbarStyle = .automatic
            restoreAllViews()
            stopViewMonitoring()
        }
        
        logger.info("🎛️ setTitleBar complete - final state: \(self.isTitleBarHidden)")
    }
    
    // MARK: - NSWindowDelegate
    
    func windowDidBecomeKey(_ notification: Notification) {
        logger.info("🔑 Window became key - isTitleBarHidden: \(self.isTitleBarHidden)")
        guard let window = notification.object as? NSWindow else { return }
        
        if isTitleBarHidden {
            logger.info("🔑 Re-applying hidden state after becoming key")
            
            // Multiple aggressive passes to catch AppKit recreation at different timing
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.isTitleBarHidden else { return }
                self.logger.info("🔑 Immediate suppression after becoming key")
                self.suppressTitleBarViews(in: window)
            }
            
            // Additional passes with different delays
            for delay in [0.01, 0.05, 0.1, 0.2, 0.5] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self = self, self.isTitleBarHidden else { return }
                    self.logger.info("🔑 Delayed suppression (\(delay)s) after becoming key")
                    self.suppressTitleBarViews(in: window)
                }
            }
        }
    }
    
    func windowDidResignKey(_ notification: Notification) {
        logger.info("🔓 Window resigned key - isTitleBarHidden: \(self.isTitleBarHidden)")
        guard let window = notification.object as? NSWindow else { return }
        
        if isTitleBarHidden {
            logger.info("🔓 Suppressing title bar after losing focus")
            
            // Immediate suppression when losing focus
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.isTitleBarHidden else { return }
                self.logger.info("🔓 Immediate suppression after losing focus")
                self.suppressTitleBarViews(in: window)
            }
            
            // Additional passes to catch AppKit recreation when not focused
            for delay in [0.01, 0.05, 0.1] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self = self, self.isTitleBarHidden else { return }
                    self.logger.info("🔓 Delayed suppression (\(delay)s) after losing focus")
                    self.suppressTitleBarViews(in: window)
                }
            }
        }
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        logger.info("🖥️ Entering full screen")
        stopViewMonitoring()
        restoreAllViews()
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
        logger.info("🪟 Exiting full screen")
        guard let window = notification.object as? NSWindow else { return }
        
        if isTitleBarHidden {
            DispatchQueue.main.async { [weak self] in
                self?.suppressTitleBarViews(in: window)
                self?.startViewMonitoring()
            }
        }
    }
    
    
    deinit {
        logger.info("💀 WindowController deinit")
        stopViewMonitoring()
    }
}