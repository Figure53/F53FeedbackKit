This is a support framework suitable for including in
Mac OS X apps that allows users to submit several pieces of information
from within the app when they are having trouble. This includes:

 * Crash reports
 * Console logs
 * Preferences
 * Document files
 * System information
 * Problem description

These are submitted to a URL as a single POST of JSON data. The JSON fields
include:

 * **type** - string representing the reason for submission. This can be:
     * *crash* - a crash occurred
     * *support* - the user requested support
     * *feedback* - the user wanted to submit general feedback
     * *exception* - an exception was raised in the app
 * **comment** - description written by the user
 * **email** - email address of the user
 * **version** - the version number of the application (text)
 * **system** - system information (text)
 * **preferences** - application preferences (text)
 * **console** - system log text. Note that this can be very large (text)
 * **documents** - a dictionary containing document files
     * key - filename
     * value - Base64 encoded zip file of the document. Note that the zip file
	    may contain a single file, or a complete folder structure.

Additional fields may be added by an application by creating a delegate class
conforming to the FRFeedbackReporterDelegate protocol.

This is a fork of the excellent [FeedbackReporter framework][1] which already
did most of what we were looking for. There are some things we'd rather do
differently though, which was the reason for this fork. These include:

 * Targeting 10.7 and beyond, as we are not interested in backwards
   compatibility beyond that.
 * Grabbing the entire console log, rather than just the messages from the
   current application.
 * Submitting to the server JSON data rather than a form.
 * Including document data in the submission.

[1]: https://github.com/tcurdt/feedbackreporter


# F53FeedbackKit_iOS

## Components

- `F53FeedbackKit_iOS` - Contains the iOS-compatible version of F53FeedbackKit.
- `iOSApp` - A version of `App` for testing feedback integration examples in the iOS SDK.

## Compatibility

- The API and the uploaded content of the iOS framework are identical to the Mac framework.
- F53FeedbackKit_iOS does not currently support the Documents tab.
- iOS does not support fetching the user's "Me" address book card, so F53FeedbackKit_iOS does not attempt to auto-fill the email address field.
- iOS prevents fetching crash logs from outside of the sandboxed app environment, so crash log text must be provided to FRFeedbackReporter  by an external source. One such approach is to use a library like [PLCrashReporter](https://www.plcrashreporter.org) to capture crash reports. Upon discovery of a new report, pass the contents of the crash report as NSString text to `[FRFeedbackReporter sharedReporter] reportCrash:`.
- System profile `CPU_SPEED` will almost always report "-1", as reportedly Apple does not provide results for `HW_CPU_FREQ` on all iOS devices. CPU speeds are, however, well-documented per device model and could be cross-referenced server-side.
- System profile will include an additional element `UUID` on iOS, which is the value of `[[UIDevice currentDevice] identifierForVendor]`.

## How To Get Started

Currently, the F53FeedbackKit Xcode project is not configured to build a 'fat' framework suitable for iOS development (meaning it does not contains support for both Simulator and device CPU architectures). To install a framework that will build in both the Simulator and on iOS devices, use CocoaPods:

- install via [CocoaPods](http://cocoapods.org)

```ruby
platform :ios, '8.4'
pod 'F53FeedbackKit_iOS', :git => 'https://github.com/Figure53/F53FeedbackKit.git', :branch => 'mac+ios'
```

- Add these key/value pairs to your app's Info.plist:
 - FRFeedbackReporter.logHours
 - FRFeedbackReporter.sendDetailsIsOptional
 - FRFeedbackReporter.targetURL
- Optionally, implement the method `feedbackControllerTintColor` in your FRFeedbackController delegate to set the default tint color of the navigation bar buttons and UI elements.

NOTE: if your targetURL server does not support HTTPS, don't forget to add the domain to your NSExceptionDomains list in the NSAppTransportSecurity dictionary.

- The iOS interface is presented by the FRFeedbackReporter delegate object if it is a subclass of UIViewController. If a delegate is not set -- or the delegate is not a view controller, the interface is presented by the root view controller of the UIApplication keyWindow object.
- The interface presents as a full-screen modal on compact interfaces and as a form sheet on regular interfaces.


## Example Implementation (using PLCrashReporter)

```objective-c
PLCrashReporter *crashReporter = [[UIApplication sharedApplication] delegate].crashReporter;
if ( [crashReporter hasPendingCrashReport] ) {
    NSData *crashData = [crashReporter loadPendingCrashReportDataAndReturnError:NULL];
    NSString *reportText = [PLCrashReportTextFormatter stringValueForCrashReport:report withTextFormat:PLCrashReportTextFormatiOS];
    BOOL reported = [[FRFeedbackReporter sharedReporter] reportCrash:reportText];
    if ( reported )
        [crashReporter purgePendingCrashReport];
}
```


## Version Support

F53FeedbackKit_iOS supports iOS 8.4+.