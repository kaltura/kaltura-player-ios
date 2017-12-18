Pod::Spec.new do |s|
  
  s.name             = 'KalturaPlayer'
  s.version          = '0.0.1'
  s.summary          = 'KalturaPlayer -- Kaltura Player for iOS'
  s.homepage         = 'https://github.com/kaltura/kaltura-player-ios'
  s.license          = { :type => 'AGPLv3', :file => 'LICENSE' }
  s.author           = { 'Kaltura' => 'community@kaltura.com' }
  s.source           = { :git => 'https://github.com/kaltura/kaltura-player-ios.git', :tag => 'v' + s.version.to_s }
  s.ios.deployment_target = '9.0'

s.subspec 'Core' do |sp|
    sp.source_files = 'Sources/Core/**/*'
    sp.dependency 'PlayKit/Core'
    sp.dependency 'PlayKitKava'
    sp.dependency 'PlayKit/KalturaStatsPlugin'
end

s.subspec 'OVP' do |sp|
    sp.source_files = 'Sources/OVP/**/*'
    sp.dependency 'KalturaPlayer/Core'
    sp.dependency 'PlayKitOVP'
end

s.subspec 'OTT' do |sp|
    sp.source_files = 'Sources/OTT/**/*'
    sp.dependency 'KalturaPlayer/Core'
    sp.dependency 'PlayKitOTT'
end

s.subspec 'UI' do |sp|
    sp.source_files = 'Sources/UI/**/*.{swift}'
    sp.resource_bundles = {
        'KalturaPlayer' => ['Sources/UI/**/*.{xcassets,storyboard,xib}']
    }
    sp.dependency 'KalturaPlayer/Core'
end

end

