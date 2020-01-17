Pod::Spec.new do |s|
  s.name                = 'F53FeedbackKit'
  s.version             = '1.5.2'
  s.summary             = 'Framework for sending feedback and system information reports from your iOS application.'
  s.license             = 'apache'
  s.homepage            = 'https://github.com/Figure53/F53FeedbackKit'
  s.authors             = 'Figure 53, LLC', 'Torsten Curdt', 'Fraser Speirs', 'Jens Alfke'
  s.source              = { :git => 'https://github.com/Figure53/F53FeedbackKit.git', :tag => "#{s.version}" }
  s.platforms           = { :ios => '9.0' }
  
  s.requires_arc        = true
  
  s.default_subspec     = "iOS"
  
  s.subspec "iOS" do |ss|
    ss.source_files     = [
      'Sources/Main/*.{h,m}', 
      'Sources/Main/iOS/*.{h,m}',
      'Sources/Resources/iOS/Base.lproj/Localizable.strings'
    ]
    ss.prefix_header_file = 'F53FeedbackKit_iOS/F53FeedbackKit_iOS.pch'
  
    ss.frameworks         = 'Foundation', 'UIKit', 'SystemConfiguration'
    ss.platform           = :ios, '9.0'
    ss.resource_bundles   = { 'F53FeedbackKit' => ['Sources/Resources/iOS/Base.lproj/*.xib'] }
  end
  
end
