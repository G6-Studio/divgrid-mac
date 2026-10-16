import AppKit
import Carbon.HIToolbox
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenu: NSMenu!
    private var showItem: NSMenuItem?
    private var settingsWindow: NSWindow?
    private var hotKey: HotKey?
    private var panels: [GridPanel] = []
    private var outline: OutlinePanel?
    private var keyMonitor: Any?
    private var pollTimer: Timer?
    private var targetWindow: AXUIElement?
    private let targetInfo = TargetInfo()
    private let idleAlpha: CGFloat = 0.6

    func applicationDidFinishLaunching(_ notification: Notification) {
        WindowMover.ensureAccessibility(prompt: true)
        setupStatusItem()
        registerHotKey()
        let nc = NotificationCenter.default
        nc.addObserver(forName: .hotKeyPause, object: nil, queue: .main) { [weak self] _ in self?.hotKey = nil }
        nc.addObserver(forName: .hotKeyChanged, object: nil, queue: .main) { [weak self] _ in self?.registerHotKey() }
    }

    private func registerHotKey() {
        hotKey = nil
        hotKey = HotKey(keyCode: Settings.hotKeyCode, modifiers: Settings.hotKeyModifiers) { [weak self] in
            self?.toggleGrid()
        }
        showItem?.title = "Show Grid  (\(Settings.hotKeyDescription))"
    }

    // MARK: Menu

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "square.grid.3x3", accessibilityDescription: "DivGrid")
        let menu = NSMenu()
        showItem = menu.addItem(withTitle: "Show Grid  (\(Settings.hotKeyDescription))",
                                action: #selector(showFromMenu), keyEquivalent: "")
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.items.forEach { $0.target = self }
        let quit = menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        statusMenu = menu
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    /// Left click toggles the grid; right (or control) click opens the menu.
    @objc private func statusItemClicked() {
        let e = NSApp.currentEvent
        if e?.type == .rightMouseUp || e?.modifierFlags.contains(.control) == true {
            statusItem.menu = statusMenu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            toggleGrid()
        }
    }

    @objc private func showFromMenu() {
        // Menu steals focus briefly; defer so the previous app is frontmost again.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { self.showGrid() }
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
            w.title = "DivGrid Settings"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            settingsWindow = w
        }
        NSApp.activate()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: Grid panel

    private func toggleGrid() { panels.isEmpty ? showGrid() : hideGrid() }

    /// Shows one grid per display; a selection on any of them places the target window on that display.
    private func showGrid() {
        guard WindowMover.ensureAccessibility(), let window = WindowMover.frontWindow() else { return }

        let width: CGFloat = 460
        let gridH = (width - 20) * CGFloat(Settings.rows) / CGFloat(Settings.columns)
        let size = NSSize(width: width, height: gridH + 20 + 36 + 8)
        for screen in NSScreen.screens {
            let p = GridPanel(contentRect: NSRect(origin: .zero, size: size),
                              styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = true
            p.level = .popUpMenu
            p.alphaValue = idleAlpha
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            p.onCancel = { [weak self] in self?.hideGrid() }
            p.isFloatingPanel = true
            p.contentView = FirstMouseHostingView(rootView: GridView(
                columns: Settings.columns, rows: Settings.rows, target: targetInfo,
                onHover: { [weak p] inside in p?.animator().alphaValue = inside ? 1 : self.idleAlpha },
                onSettings: { [weak self] in self?.hideGrid(); self?.openSettings() },
                onSelect: { [weak self] cols, rows in self?.apply(cols: cols, rows: rows, on: screen) }))
            let f = screen.visibleFrame
            p.setFrameOrigin(NSPoint(x: f.midX - size.width / 2, y: f.midY - size.height / 2))
            p.orderFrontRegardless()
            panels.append(p)
        }

        outline = OutlinePanel()
        setTarget(window)

        // The panels never take focus, so clicking another window/app changes which one is frontmost.
        pollTimer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in self?.refreshTarget() }
        RunLoop.main.add(pollTimer!, forMode: .common)
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] e in
            if e.keyCode == UInt16(kVK_Escape) { self?.hideGrid() }
        }
    }

    private func hideGrid() {
        panels.forEach { $0.orderOut(nil) }
        panels = []
        outline?.orderOut(nil)
        outline = nil
        pollTimer?.invalidate(); pollTimer = nil
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        targetWindow = nil
    }

    private func setTarget(_ window: AXUIElement) {
        targetWindow = window
        if let pid = WindowMover.pid(of: window), let app = NSRunningApplication(processIdentifier: pid) {
            targetInfo.icon = app.icon
            targetInfo.appName = app.localizedName ?? ""
        }
        targetInfo.windowTitle = WindowMover.title(of: window)
        updateOutline()
    }

    private func refreshTarget() {
        // frontWindow() is nil while we're frontmost or the app has no window; keep the last target then.
        if let w = WindowMover.frontWindow(), targetWindow.map({ !CFEqual($0, w) }) ?? true {
            setTarget(w)
        } else {
            updateOutline()
        }
    }

    private func updateOutline() {
        guard let w = targetWindow, let f = WindowMover.appKitFrame(of: w) else { outline?.orderOut(nil); return }
        outline?.setFrame(f, display: true)
        outline?.orderFront(nil)
    }

    private func apply(cols: ClosedRange<Int>, rows: ClosedRange<Int>, on screen: NSScreen) {
        if let w = targetWindow { WindowMover.place(w, screen: screen, cols: cols, rows: rows) }
        hideGrid()
    }
}
