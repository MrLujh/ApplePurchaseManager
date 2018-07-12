Pod::Spec.new do |s|
s.name        = 'ApplePurchaseManager'
s.version     = '0.0.1'
s.authors     = { 'daniulaolu' => '287929070@qq.com' }
s.homepage    = 'https://github.com/MrLujh/ApplePurchaseManager'
s.summary     = 'ApplePurchase'
s.source      = { :git => 'https://github.com/MrLujh/ApplePurchaseManager.git',
:tag => s.version.to_s }
s.license     = { :type => "MIT", :file => "LICENSE" }
s.platform = :ios, '8.0'
s.requires_arc = true
s.public_header_files = 'ApplePurchaseManager/ApplePurchaseManager.h'
s.source_files = 'ApplePurchaseManager/**/*.{h,m}'
s.ios.deployment_target = '7.0'


s.dependency 'SVProgressHUD'
#s.dependency 'StoreKit'
end