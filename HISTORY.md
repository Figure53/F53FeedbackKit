## Version 1.5.3
* [ADD] Appends details of main process binary image to exception reports to facilitate symbolication.

## Version 1.5.2
* [FIX] The CocoaPods podspec for iOS now includes the required .pch file, which fixes the missing `FRLocalizedString` definition when integrating using CocoaPods.
* [CHG] CocoaPods integration requires gem version 1.8.0+.

## Version 1.5.1
* [CHG] Restores `FRLocalizedString()` macro to fix localizations when building as a framework.

## Version 1.5.0
* [FIX] Fixes a deprecation warning by migrating from NSURLConnection to NSURLSession.
* [CHG] Compatibility fixes for iOS 13.
* [CHG] iOS target now requires 9.0+.
* [ADD] Adds new optional delegate method `feedbackControllerTextScale` on iOS to allow customizing the scale of the display text.

## Version 1.4.1
* [CHG] Adds support for Dynamic Type font sizes on iOS.

## Version 1.4.0
* [FIX] Fixes “implicitly retains ‘self’” compiler warnings.
* [FIX] Namespaces method names for categories on Foundation classes to prevent collisions with other categories implementing the same method name.
* [FIX] Fixes NSApplicationDelegate for example project "App" builds.
* [CHG] Enables presenting Feedback Controller from an iOS view controller that itself is already being presented.
* [CHG] Fixes localization in example apps by renaming all "FeedbackReporter.strings" files to "Localizable.strings".
* [CHG] Modernizes code, adding nullable annotations and generics.
* [CHG] Updates structure of example project.
* [CHG] The example project no longer codesigns framework builds, in accordance with Apple-recommended Xcode project settings.
* [CHG] App Transport Security is disabled in "Document App" to allow simple testing to local test servers.
* [CHG] Mac target now requires 10.10+.


## Version 1.3.6
* [CHG] Replaces `FRLocalizedString()` macro with `NSLocalizedString()`.
* [CHG] Moves iOS-specific resource files to their own subfolder inside Base.lproj.
* [CHG] Renames the CocoaPods podspec to "F53FeedbackKit" and adds an iOS-specific default subspec. To include F53FeedbackKit in your iOS project, specify either  `pod 'F53FeedbackKit'` or `pod 'F53FeedbackKit/iOS'`.
* [CHG] Removes unneeded iOS checkmark cell .xib.
* [FIX] Several fixes to the sample Xcode project and iOS test app.


## Version 1.3.5
* [FIX] Mac crash reports were not getting submitted.
* [FIX] Mac Address Book enumeration is now done correctly.
* [FIX] Certain CPU types unavailable in Xcode 8.
* [ADD] Additional CPU types available in Xcode 8.


## Version 1.3.4
* [ADD] Adds new optional delegate method `customizeConsoleLogForFeedbackReportSince:maxSize:` to allow overriding or adding additional text to the console log.
* [ADD] Adds new optional delegate method `customizeFeedbackHeading:forType:` to allow customizing the default heading text per feedback type.
* [ADD] Adds new optional delegate method `customizeFeedbackSubheading:forType:` to allow customizing the default subheading text per feedback type.
* [FIX] Prevents a crash if (FRFeedbackReporter.maxConsoleLogSize) is set as String type.
* [FIX] Adds support for using plist types Boolean and Number.


## Version 1.3.3
* [FIX] iOS framework now works when (FRFeedbackReporter.sendDetailsIsOptional) is NO;
* [FIX] iOS "Include console logs" spinner is now visible.
* [FIX] iOS details text view is no longer editable.
* [ADD] Adds option to default to including console logs when sending details is optional (FRFeedbackReporter.defaultIncludeConsole).


## Version 1.3.2
* [ADD] Adds iOS-compatible UI.
* [ADD] Adds Cocoapods podspec for creating iOS Framework.
* [ADD] Adds new method `reportCrash:` to report externally-collected crash reports.
* [ADD] Adds new optional delegate method `feedbackControllerTintColor` to allow  overriding the interface tint color for the iOS view controller navigation button text and various UI elements.
* [CHG] Rebuilt project for Xcode 6.
* [CHG] Adopts ARC for Mac and iOS.
* [CHG] Mac target requires 10.8+.
* [ADD] iOS target requires 8.4+.


## Version 1.3.1, unreleased
* [ADD] Added Spanish translation. Thanks to Emilio Perez.
* [ADD] Added `targetUrlForFeedbackReport` to delegate protocol. Thanks to Rick Fillion.
* [FIX] Don't cache server response. Thanks to Rick Fillion.
* [FIX] PLIST_KEY_LOGHOURS should come from the info plist. Thanks to Rico.
* [CHG] Link against Foundation and 10.4 compatibility. Thanks to Linas Valiukas.


## Version 1.3.0, released 18.06.2010

New localizations. New options. Many little fixes. Better CPU detection.
Garbage Collection ready. Ready for inclusion into plugins.

* [FIX] Use @loader_path instead of @executable_path.
* [FIX] Fixed a missing boundary in POSTs.
* [FIX] Catch exceptions also outside of the main thread.
* [FIX] Improved CPU detection.
* [ADD] Changed FRFeedbackReporterDelegate to a real @protocol.
* [ADD] Added support for Garbage Collection.
* [ADD] Added anonymizePreferencesForFeedbackReport delegate method to anonymize logs.
* [ADD] Added option to restrict the log size (FRFeedbackReporter.maxConsoleLogSize).
* [ADD] Added option to opt-out from sending details (FRFeedbackReporter.sendDetailsIsOptional).
* [ADD] Added Armenian translation. Thanks to Gevorg Hakobyan (www.gevorghakobyan.uni.cc).
* [ADD] Added French translation. Thanks to Gevorg Hakobyan (www.gevorghakobyan.uni.cc) and Sylvain.
* [ADD] Added Italian translation. Thanks to Andrea.


## Version 1.2.0, released 29.09.2009

New UI layout, Dropped support for Tiger, Updated for Snow Leopard

* [DEL] Dropped support for Tiger.
* [ADD] Added support for Snow Leopard. Build now also includes 64-bit architecture.
* [ADD] Added Russion translation. Thanks to Максим Буринов
* [CHG] Changed the UI layout to be a more Mac-like. Thanks to Philipp Mayerhofer.


## Version 1.1.4, released 04.07.2009

Asynchronous gathering of system information. Shows all email addresses. Fixed some bugs/crashes.

* [FIX] Fixed a syntax error in the php server script.
* [FIX] Properly synchronize dialog composition.
* [FIX] Only catch the first exception.
* [CHG] Show all email addresses from addressbook.
* [ADD] Asynchronous gathering of system information.
* [ADD] Added Mantis integration.


## Version 1.1.3, released 30.04.2009

Fixex some reported crashes, improved CPU detection, added the option to use
addressbook email instead of anonymous

* [FIX] Improperly retained log information caused crashes.
* [FIX] Not checking for ASL results caused crashes.
* [FIX] Read-only tableview.
* [CHG] More detailed CPU detection on 10.5+.
* [ADD] Preset email address from addressbook if key FRFeedbackReporter.addressbookEmail is present.
* [ADD] Send along the type of the report (feedback/exception/crash).
* [ADD] Include full Xcode project into release.


## Version 1.1.2, released 12.02.2009

Prefixed the internal classes and some small fixes. Console log time window
now configurable.

* [CHG] Prefixed also the internal classes.
* [CHG] Less logging.
* [FIX] Escape the feedback URL.
* [FIX] Fixed spelling mistake in English localization.
* [FIX] Retain the tabs properly.
* [FIX] Fixed the app example to call framework in applicationDidFinishLaunching.
* [ADD] Made the log time window to send configurable.


## Version 1.1.0, released 09.08.2008

This is a release with some major changes. A non-modal window makes it more
user friendly. The UI has been refined a bit. Deprecated API methods have been
removed and a German localization has been added. Please contact me for
localization in other languages.

* [CHG] Uses a non-modal window now!
* [CHG] Different messages depending on how invoked.
* [CHG] Only send the latest crash report.
* [CHG] Only show relevant tabs.
* [CHG] Restrict the ASL log information.
* [CHG] Show system profile in table.
* [CHG] Use scrollers and don't break the lines.
* [CHG] Server script can now auto-add new project.
* [CHG] FRFeedbackReport should now be used as a Singleton.
* [DEL] Removed deprecated methods.
* [DEL] Removed a dedicated user attribute.
* [ADD] Now supports delegation. Custom values can be send along.
* [ADD] German localization.


## Version 1.0.1, released 01.06.2008

A critical bug fix release in terms of the CPU detection. Quite a few other
additions. Please note that the API has slightly changed.

* [FIX] CPU detection caused crashes on PPC.
* [FIX] Script output sometimes did not get fully included.
* [CHG] Slightly changed the API and deprecated the old hooks.
* [CHG] No dialog on successful transmission.
* [ADD] Support for catching uncaught exceptions.
* [ADD] Auto-select tab.
* [ADD] Upload data asynchronously.
* [ADD] Cancel data transmission.
* [ADD] Alert dialog if transmission failed.
* [ADD] Report number of CPUs.


## Version 1.0.0, released 19.05.2008

Initial release!
