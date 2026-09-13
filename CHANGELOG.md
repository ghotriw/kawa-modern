## 2.0.2 (13 Sep 2026)

* Update CI build environment to `macos-26` runner for modern macOS appearance and controls
* Refine preferences window styling for seamless appearance

## 2.0.1 (13 Sep 2026)

* Rebrand project as **Kawa Modern** with bundle identifier `com.ghotriw.Kawa`
* Add automatic settings and hotkey migration from legacy Kawa installations
* Fix deprecation warning for `IconRef` rendering using `PlotIconRefInContext`
* Clean up obsolete Carthage dependencies (`Cartfile`) and legacy test targets
* Update documentation, screenshots, and Homebrew tap installation instructions

## 2.0.0 (13 Sep 2026)

* Modernize settings interface using SwiftUI and native AppKit components
* Fix shortcut activation on startup: hotkeys now work immediately without opening preferences
* Replace MASShortcut and Carthage with a zero-dependency native Carbon HotKey engine targeting `GetEventDispatcherTarget`
* Add automatic conflict resolution and migration for configured shortcuts
* Add native Launch at Login support via ServiceManagement (`SMAppService`)
* Modernize notifications with `UserNotifications.framework`
* Update minimum deployment target to macOS 13.0

## 1.2.0 (4 Sep 2026)

* Support Apple Silicon (M1/M2/M3/M4, `arm64`) and Intel (`x86_64`) natively as Universal 2 binary
* Update minimum macOS deployment target to macOS 11.0
* Add automated build and release GitHub Actions workflow

## 1.1.0 (10 Nov 2017)

* Remove previous notifications on new one (#17)

## 1.0.1 (18 Sep 2017)

* Make statusbar icon visible in dark UI

## 1.0.0 (16 Sep 2017)

* Add an option to show macOS notification on source change (#9)
* Implement a proper workaround for the known CJKV bug (#12)
* Update licenses for 2017
* Minor code refactoring

## 0.1.3 (3 Oct 2016)

* Use Swift 3
* Remove 'advanced input switching'

## 0.1.2 (6 Aug 2015)

* Change 'simple method' option to 'advanced method' option.
* Open 'Preferences' initially only for the first launch.

## 0.1.0 (6 Aug 2015)

* Initial release
