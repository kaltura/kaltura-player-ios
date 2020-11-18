suffix = '.0000'   # Dev mode
# suffix = ''       # Release

playkitVersion = '3.18'

Pod::Spec.new do |s|
  
  s.name             = 'KalturaPlayer'
  s.version          = '4.0.0' + suffix
  s.summary          = 'KalturaPlayer -- Kaltura Player for iOS'
  s.homepage         = 'https://github.com/kaltura/kaltura-player-ios'
  s.license          = { :type => 'AGPLv3', :file => 'LICENSE' }
  s.author           = { 'Kaltura' => 'community@kaltura.com' }
  s.source           = { :git => 'https://github.com/kaltura/kaltura-player-ios.git', :tag => 'v' + s.version.to_s }
  s.swift_version    = '5.0'
  
  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'
  
  s.subspec 'Core' do |sp|
    sp.source_files = 'Sources/*', 'Sources/Basic/**/*'
    
    sp.dependency 'PlayKit', '~> ' + play_kit_version
    
  end
  
  s.subspec 'OTT' do |sp|
    sp.source_files = 'Sources/OTT/*', 'Sources/Common'
    sp.resources = 'Sources/OTT/*.xcdatamodeld'
    
    sp.dependency 'KalturaPlayer/Core'
    sp.dependency 'PlayKitProviders', '~> 1.8'
    sp.dependency 'PlayKitKava', '~> 1.6'
  end

  s.subspec 'OVP' do |sp|
    sp.source_files = 'Sources/OVP/*', 'Sources/Common'
    sp.resources = 'Sources/OVP/*.xcdatamodeld'
    
    sp.dependency 'KalturaPlayer/Core'
    sp.dependency 'PlayKitProviders', '~> 1.8'
    sp.dependency 'PlayKitKava', '~> 1.6'
  end
  
  s.subspec 'Interceptor' do |sp|
    sp.source_files = 'Sources/Basic/Interceptor/*'
    
    sp.dependency 'PlayKit', '~> ' + play_kit_version
  end
  
=begin
Removing Offline until a fix will be provided by Cocoapods or Realm for the release in Xcode 12.
https://github.com/realm/realm-cocoa/issues/6800

  s.subspec 'Offline' do |sp|
    sp.source_files = 'Sources/Offline/*'
    
    sp.dependency 'KalturaPlayer/Core'
    sp.dependency 'DownloadToGo', '~> 3.12'
  end

  s.subspec 'Offline_OTT' do |sp|
    sp.source_files =  'Sources/Offline/OTT/*'

    sp.dependency 'KalturaPlayer/Offline'
    sp.dependency 'KalturaPlayer/OTT'
  end

  s.subspec 'Offline_OVP' do |sp|
    sp.source_files =  'Sources/Offline/OVP/*'

    sp.dependency 'KalturaPlayer/Offline'
    sp.dependency 'KalturaPlayer/OVP'
  end
=end
  
  s.default_subspec = 'Core'
end

