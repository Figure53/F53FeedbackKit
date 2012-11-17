This will be (but is not yet) a support framework suitable for including in
Mac OS X apps that will allow users to submit several pieces of information
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

