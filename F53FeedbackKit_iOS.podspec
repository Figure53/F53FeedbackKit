Pod::Spec.new do |s|
  s.name                = 'F53FeedbackKit_iOS'
  s.version             = '1.3.4'
  s.summary             = 'Framework for sending feedback and system information reports from your iOS application.'
  s.license             = 'apache'
  s.source              = { :git => 'https://github.com/Figure53/F53FeedbackKit.git', :tag => '1.3.4' }
  s.platform            = :ios, '8.4'
  s.authors             = 'Figure 53, LLC', 'Torsten Curdt', 'Fraser Speirs', 'Jens Alfke'
  s.homepage            = 'https://github.com/Figure53/F53FeedbackKit'
  s.prefix_header_file  = 'F53FeedbackKit_iOS/F53FeedbackKit_iOS.pch'
  s.source_files        = 'F53FeedbackKit_iOS/*.{h,m}', 'Sources/Main/*.{h,m}', 'Sources/Main/iOS/*.{h,m}'
  s.resource_bundles    = {
      'F53FeedbackKit_iOS' => ['Sources/Resources/Base.lproj/FRiOS*.xib',
                               'Sources/Resources/Base.lproj/FeedbackReporter_iOS.strings'],
  }
  s.frameworks          = 'Foundation', 'UIKit', 'SystemConfiguration'
  s.requires_arc        = true
end
