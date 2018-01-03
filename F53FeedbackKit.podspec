Pod::Spec.new do |s|
  s.name                = 'F53FeedbackKit'
  s.version             = '1.3.6'
  s.summary             = 'Framework for sending feedback and system information reports from your iOS application.'
  s.license             = 'apache'
  s.homepage            = 'https://github.com/Figure53/F53FeedbackKit'
  s.authors             = 'Figure 53, LLC', 'Torsten Curdt', 'Fraser Speirs', 'Jens Alfke'
  s.source              = { :git => 'https://github.com/Figure53/F53FeedbackKit.git', :tag => "#{s.version}" }
  s.platforms           = { :ios => '8.4' }
  
  s.requires_arc        = true
  
  s.default_subspec     = "iOS"
  
  s.subspec "iOS" do |ss|
    ss.source_files     = [
      'Sources/Main/*.{h,m}', 
      'Sources/Main/iOS/*.{h,m}',
      'Sources/Resources/Base.lproj/FeedbackReporter_iOS.strings'
    ]
  
    ss.platform           = :ios, '8.4'
    ss.frameworks         = 'Foundation', 'UIKit', 'SystemConfiguration'
    ss.resource_bundles   = { 'F53FeedbackKit' => ['Sources/Resources/Base.lproj/iOS/*.xib'] }
  end
  
end
