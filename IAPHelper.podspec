Pod::Spec.new do |s|

  s.name         = "IAPHelper"
  s.version      = "1.0.8.1"
  s.summary      = "In App Purchases Helper."
  s.homepage     = "https://github.com/saturngod/IAPHelper"
  s.license  = "MIT"
  s.author       = { "saturngod" => "saturngod@gmail.com" }
  s.requires_arc = true
  s.platform     = :ios
  s.platform     = :ios, '6.0'
  s.source       = { :git => "https://github.com/saturngod/IAPHelper.git", :tag => "1.0.8.1" }
  s.source_files = "IAPHelper/*.{h,m}"
  s.public_header_files = "IAPHelper/*.h"
  s.framework  = 'StoreKit'
  
end
