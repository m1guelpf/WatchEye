import Cocoa
import OSLog
import AXSwift
import Foundation

private let logger = Logger(subsystem: "build.miguel.WatchEye", category: "WatchEye")

public protocol WatchEyeDelegate {
    /// Notifies you that the user has granted accessibility permissions.
    /// If the user had previously granted access, this is called immediately.
    func watchEyeDidReceiveAccessibilityPermissions(_ watchEye: WatchEye)

    /// Tells the delegate that the focused application has changed.
    func watchEye(_ watchEye: WatchEye, didFocusApplication application: NSRunningApplication)

    /// Tells the delegate that the window title of the focused application has changed.
    func watchEye(_ watchEye: WatchEye, didChangeTitleOf application: NSRunningApplication, newTitle title: String)
}

@Observable
public final class WatchEye: NSObject {
    /// The delegate for the watcher.
    @ObservationIgnored public var delegate: WatchEyeDelegate?

    private var observers: [String: Observer] = [:]
    private var windowObserver: (any NSObjectProtocol)? = nil

    // Handling registration after the user has granted access.
    private var permissionCheckTimer: Timer? = nil
    private var shouldRequestAccessLater: [NSRunningApplication] = []

    /// Whether the app has accessibility permissions.
    public var isAllowed: Bool {
        access(keyPath: \.isAllowed)
        return AXIsProcessTrusted()
    }

    override public required init() {
        super.init()

        ensureAccessibilityPermission()

        NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier != nil && $0.bundleIdentifier != Bundle.main.bundleIdentifier && $0.activationPolicy == .regular
        }.forEach(startObserving)

        windowObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil,
            using: onApplicationChange
        )
    }

    deinit {
        observers.forEach { $0.value.stop() }
        if let permissionCheckTimer { permissionCheckTimer.invalidate() }
        if let windowObserver { NSWorkspace.shared.notificationCenter.removeObserver(windowObserver) }
    }

    /// Whether initialising `WatchEye` will prompt the user for accessibility permissions.
    public static func willPromptForAccess() -> Bool {
        return !AXIsProcessTrusted()
    }

    private func ensureAccessibilityPermission() {
        let options: NSDictionary = ["AXTrustedCheckOptionPrompt": true]
        let isTrusted = AXIsProcessTrustedWithOptions(options)

        if isTrusted {
            delegate?.watchEyeDidReceiveAccessibilityPermissions(self)
            return
        }

        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard self.isAllowed else { return }

            self.permissionCheckTimer?.invalidate()
            self.permissionCheckTimer = nil

            self.shouldRequestAccessLater.forEach(self.startObserving)
            self.shouldRequestAccessLater.removeAll()

            self.withMutation(keyPath: \.isAllowed) {}
            self.delegate?.watchEyeDidReceiveAccessibilityPermissions(self)
        }
    }

    private func onApplicationChange(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication, let bundleIdentifier = app.bundleIdentifier else { return }

        if !observers.contains(where: { $0.key == bundleIdentifier }) {
            startObserving(app)
        }

        delegate?.watchEye(self, didFocusApplication: app)
    }

    private func startObserving(_ app: NSRunningApplication) {
        guard let application = Application(app), let observer = application.createObserver({ _, element, event in
            if event == .titleChanged {
                guard let title = try? (element.attribute(.title) as String?) else { return }

                self.delegate?.watchEye(self, didChangeTitleOf: app, newTitle: title)
            }

            if event == .applicationActivated {
                guard let focusedWindow: UIElement = try? element.attribute(Attribute.focusedWindow) else { return }
                guard let title = try? (focusedWindow.attribute(.title) as String?) else { return }

                self.delegate?.watchEye(self, didChangeTitleOf: app, newTitle: title)
            }
        }) else { return }

        do {
            try observer.addNotification(.titleChanged, forElement: application)
            try observer.addNotification(.applicationActivated, forElement: application)
        } catch {
            observer.stop()

            if let error = error as? AXError, error == .apiDisabled {
                shouldRequestAccessLater.append(app)
            }

            logger.error("Failed to add notification for \(app.bundleIdentifier!): \(error)")
            return
        }

        observers[app.bundleIdentifier!] = observer
    }
}
