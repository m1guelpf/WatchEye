# A simple Swift library for watching over your macOS activity

[![Install Size](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fwww.emergetools.com%2Fapi%2Fv2%2Fpublic_new_build%3FexampleId%3DWatchEye.WatchEye%26platform%3Dmacos%26badgeOption%3Dmax_install_size_only%26buildType%3Drelease&query=$.badgeMetadata&label=WatchEye&logo=apple)](https://www.emergetools.com/app/example/ios/WatchEye.WatchEye/release)
[![Swift Version](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fm1guelpf%2FWatchEye%2Fbadge%3Ftype%3Dswift-versions&color=brightgreen)](https://swiftpackageindex.com/m1guelpf/WatchEye)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/m1guelpf/WatchEye/main/LICENSE)

This library sits on top of the macOS Accessibility API, making it easy to react when the user changes the active application, or when the window the user is focused on changes its title. This is very convenient when building time-tracking applications.

## Installation

### Swift Package Manager

The Swift Package Manager allows for developers to easily integrate packages into their Xcode projects and packages; and is also fully integrated into the swift compiler.

### SPM Through XCode Project

-   File > Swift Packages > Add Package Dependency
-   Add https://github.com/m1guelpf/WatchEye.git
-   Select "Branch" with "main"

### SPM Through Xcode Package

Once you have your Swift package set up, add the Git link within the dependencies value of your Package.swift file.

```swift
dependencies: [
    .package(url: "https://github.com/m1guelpf/WatchEye.git", .branch("main"))
]
```

## Getting started 🚀

The easiest way to get started is to define a delegate and start reacting to events:

```swift
import AppKit
import WatchEye
import Foundation

class ExampleWatchEyeDelegate {
	let watchEye: WatchEye

	init() {
		watchEye = WatchEye()
		watchEye.delegate = self
	}
}

extension ExampleWatchEyeDelegate: WatchEyeDelegate {
	func watchEyeDidReceiveAccessibilityPermissions(_: WatchEye) {
        print("Accessibility permissions granted!")
    }

	func watchEye(_: WatchEye, didFocusApplication app: NSRunningApplication) {
        print("\(app.bundleIdentifier!) is now in focus")
    }

	func watchEye(_: WatchEye, didChangeTitleOf app: NSRunningApplication, newTitle title: String) {
		print("Title of \(app.bundleIdentifier!) changed to \(title)")
	}
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
