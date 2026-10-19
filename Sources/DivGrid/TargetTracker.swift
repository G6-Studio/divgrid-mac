import AppKit
import ApplicationServices

/// What the grid header shows about the window that will be resized.
@MainActor
final class TargetInfo: ObservableObject {
    @Published var icon: NSImage?
    @Published var appName = ""
    @Published var windowTitle = ""
}

/// Follows the frontmost window while the grid is open, without polling.
///
/// App switches come from `NSWorkspace`. Within an app, an `AXObserver` reports focus changes between
/// its windows, and moves, resizes, title changes and closing of the current target.
@MainActor
final class TargetTracker {
    let info = TargetInfo()
    private(set) var window: AccessibilityWindow?

    /// Called when the target window changes or its frame moves, so the outline can follow it.
    var onChange: (() -> Void)?

    private var observer: AXObserver?
    private var observedPID: pid_t?
    private var activationToken: NSObjectProtocol?

    private static let windowNotifications = [
        kAXMovedNotification, kAXResizedNotification, kAXTitleChangedNotification,
        kAXUIElementDestroyedNotification,
    ]

    // The AXObserver holds an unretained pointer to `self`; make sure it can't outlive us.
    isolated deinit { tearDownObserver() }

    func start(initial: AccessibilityWindow) {
        activationToken = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let pid = app?.processIdentifier
            MainActor.assumeIsolated { self?.applicationActivated(pid: pid) }
        }
        setTarget(initial)
    }

    func stop() {
        if let activationToken { NSWorkspace.shared.notificationCenter.removeObserver(activationToken) }
        activationToken = nil
        tearDownObserver()
        window = nil
        onChange = nil
    }

    // MARK: Target selection

    private func applicationActivated(pid: pid_t?) {
        // Our own windows (e.g. settings) activating the app must not become the target.
        guard let pid, pid != ProcessInfo.processInfo.processIdentifier else { return }
        // An app with no focused window keeps the previous target.
        if let focused = AccessibilityWindow.focused(pid: pid) { setTarget(focused) }
    }

    private func setTarget(_ newWindow: AccessibilityWindow) {
        if let old = window, let observer { removeWindowNotifications(from: old, observer: observer) }
        window = newWindow

        if let pid = newWindow.pid {
            if let app = NSRunningApplication(processIdentifier: pid) {
                info.icon = app.icon
                info.appName = app.localizedName ?? ""
            }
            if observedPID != pid { observeApplication(pid: pid) }
        }
        info.windowTitle = newWindow.title
        if let observer { addWindowNotifications(to: newWindow, observer: observer) }
        onChange?()
    }

    // MARK: AXObserver

    private func observeApplication(pid: pid_t) {
        tearDownObserver()
        var created: AXObserver?
        let error = AXObserverCreate(pid, accessibilityCallback, &created)
        guard error == .success, let created else {
            Log.window.error("Cannot observe pid \(pid): AXError \(error.rawValue)")
            return
        }
        let app = AXUIElementCreateApplication(pid)
        let status = AXObserverAddNotification(
            created, app, kAXFocusedWindowChangedNotification as CFString, refcon)
        if status != .success {
            Log.window.error("Cannot watch focus changes for pid \(pid): AXError \(status.rawValue)")
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(created), .commonModes)
        observer = created
        observedPID = pid
    }

    private func tearDownObserver() {
        if let observer {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        }
        observer = nil
        observedPID = nil
    }

    private var refcon: UnsafeMutableRawPointer {
        Unmanaged.passUnretained(self).toOpaque()
    }

    private func addWindowNotifications(to window: AccessibilityWindow, observer: AXObserver) {
        for name in Self.windowNotifications {
            let status = AXObserverAddNotification(observer, window.element, name as CFString, refcon)
            // Some apps don't support every notification; the rest still work.
            if status != .success && status != .notificationAlreadyRegistered {
                Log.window.debug("Notification \(name) unavailable: AXError \(status.rawValue)")
            }
        }
    }

    private func removeWindowNotifications(from window: AccessibilityWindow, observer: AXObserver) {
        for name in Self.windowNotifications {
            AXObserverRemoveNotification(observer, window.element, name as CFString)
        }
    }

    fileprivate func handle(notification name: String) {
        switch name {
        case kAXFocusedWindowChangedNotification:
            if let pid = observedPID, let focused = AccessibilityWindow.focused(pid: pid) { setTarget(focused) }
        case kAXTitleChangedNotification:
            info.windowTitle = window?.title ?? ""
        case kAXUIElementDestroyedNotification:
            window = nil
            info.windowTitle = ""
            onChange?()
        default:  // moved, resized
            onChange?()
        }
    }
}

/// C callback for AXObserver. The observer's run loop source is on the main run loop.
private let accessibilityCallback: AXObserverCallback = { _, _, notification, refcon in
    guard let refcon else { return }
    let tracker = Unmanaged<TargetTracker>.fromOpaque(refcon).takeUnretainedValue()
    let name = notification as String
    MainActor.assumeIsolated { tracker.handle(notification: name) }
}
