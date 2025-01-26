import AppKit
import Foundation
import ScriptingBridge

public enum BrowserUtils: String, CaseIterable {
    case brave = "com.brave.Browser"
    case safari = "com.apple.Safari"
    case chrome = "com.google.Chrome"
    case arc = "company.thebrowser.Browser"

    public init?(app: NSRunningApplication) {
        for browser in BrowserUtils.allCases {
            if app.bundleIdentifier == browser.rawValue {
                self = browser
                return
            }
        }

        return nil
    }

    public func isIncognito(windowTitle: String? = nil) -> Bool? {
        switch self {
            case .arc, .brave, .chrome:
                guard let chromium: ChromiumProtocol = SBApplication(bundleIdentifier: rawValue),
                      let frontWindow = chromium.windows?().first,
                      let mode = frontWindow.mode else { return nil }

                return mode == "incognito"

            case .safari:
                guard let title = windowTitle else { return nil }
                return title.contains("Private Browsing")
        }
    }

    public func getURL() -> URL? {
        switch self {
            case .arc, .brave, .chrome:
                guard let chromium: ChromiumProtocol = SBApplication(bundleIdentifier: rawValue),
                      let frontWindow = chromium.windows?().first,
                      let activeTab = frontWindow.activeTab,
                      let url = activeTab.URL, let url = URL(string: url) else { return nil }

                return url
            case .safari:
                guard let safari: SafariProtocol = SBApplication(bundleIdentifier: rawValue),
                      let frontWindow = safari.windows?().first,
                      let activeTab = frontWindow.currentTab,
                      let url = activeTab.URL, let url = URL(string: url) else { return nil }

                return url
        }
    }
}

public extension NSRunningApplication {
    var browser: BrowserUtils? {
        BrowserUtils(app: self)
    }
}

@objc protocol SBApplicationProtocol {
    func activate()
    var isRunning: Bool { get }
    var delegate: SBApplicationDelegate! { get set }
}

@objc protocol ChromiumProtocol: SBApplicationProtocol {
    @objc optional func windows() -> [ChromiumWindow]
}

@objc protocol SafariProtocol: SBApplicationProtocol {
    @objc optional func windows() -> [SafariWindow]
}

@objc protocol ChromiumWindow {
    /// Represents the mode of the window which can be 'normal' or 'incognito'.
    @objc optional var mode: String { get }
    /// Returns the currently selected tab
    @objc optional var activeTab: ChromiumTab { get }
}

@objc protocol SafariWindow {
    /// The current tab.
    @objc optional var currentTab: SafariTab { get }
}

@objc protocol ChromiumTab {
    /// The url visible to the user.
    @objc optional var URL: String { get }
    /// The title of the tab.
    @objc optional var title: String { get }
}

@objc protocol SafariTab {
    /// The current URL of the tab.
    @objc optional var URL: String { get }
    /// The name of the tab.
    @objc optional var name: String { get }
}

extension SBApplication: ChromiumProtocol, SafariProtocol {}
extension SBObject: ChromiumWindow, SafariWindow, ChromiumTab, SafariTab {}
