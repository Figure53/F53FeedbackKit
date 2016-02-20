Pod::Spec.new do |s|
  s.name                = "F53FeedbackKit_iOS"
  s.version             = "1.3.3"
  s.summary             = "Framework for sending feedback and system information reports from your iOS application."
  s.license             = "apache"
  s.source              = { :git => "https://github.com/Figure53/F53FeedbackKit.git" }
  s.platform            = :ios, "8.4"
  s.prefix_header_file  = "F53FeedbackKit_iOS/F53FeedbackKit_iOS.pch"
  s.source_files        = "F53FeedbackKit_iOS/*.{h,m}", "Sources/Main/*.{h,m}", "Sources/Main/iOS/*.{h,m}"
  s.resource_bundles    = {
      'F53FeedbackKit_iOS' => ["Sources/Resources/Base.lproj/FRiOS*.xib",
                               "Sources/Resources/Base.lproj/FeedbackReporter_iOS.strings"],
  }
  s.frameworks          = "Foundation", "UIKit", "SystemConfiguration"
  s.requires_arc        = true
end
