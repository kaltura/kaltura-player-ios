suffix = ''   # Dev mode
# suffix = ''       # Release


Pod::Spec.new do |s|
  
  s.name             = 'KalturaPlayer'
  s.version          = '4.10.1' + suffix
  s.summary          = 'KalturaPlayer -- Kaltura Player for iOS and tvOS'
  s.homepage         = 'https://github.com/kaltura/kaltura-player-ios'
  s.license          = { :type => 'AGPLv3', :file => 'LICENSE' }
  s.author           = { 'Kaltura' => 'community@kaltura.com' }
  s.source           = { :git => 'https://github.com/kaltura/kaltura-player-ios.git', :tag => 'v' + s.version.to_s }
  s.swift_version    = '5.0'
  
  s.ios.deployment_target = '15.0'
  s.tvos.deployment_target = '15.0'
  
  s.subspec 'Interceptor' do |sp|
    sp.source_files = 'Sources/Interceptor/*'
    
    sp.dependency 'PlayKit', '~> 3.31'
  end
  
  # Fix pod lint error: could not find module for target 'arm64-apple-ios-simulator'
  # This error indicates that a pod dependency in your project doesn't have a compiled version for the arm64 architecture of the iOS simulator.
  # This is because Apple Silicon Macs (M1, M2, etc.) use arm64 architecture, while Intel Macs use x86_64.
  # see: https://stackoverflow.com/a/63955114/1571228
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  
  ################################################################
  
  s.subspec 'Core' do |sp|
    sp.ios.deployment_target = '15.0'
    sp.tvos.deployment_target = '15.0'
    
    sp.source_files = 'Sources/*', 'Sources/Basic/*', 'Sources/Playlist/*'
    
    sp.dependency 'KalturaPlayer/Interceptor'
  end
  
    s.subspec 'OTT' do |sp|
    sp.source_files = 'Sources/OTT/*', 'Sources/Common'
    sp.resources = 'Sources/OTT/*.xcdatamodeld'
    
    sp.dependency 'KalturaPlayer/Core'
    sp.dependency 'PlayKitProviders', '~> 1.19'
    sp.dependency 'PlayKitKava', '~> 1.11'
  end
  
  s.subspec 'OVP' do |sp|
    sp.source_files = 'Sources/OVP/*', 'Sources/Common'
    sp.resources = 'Sources/OVP/*.xcdatamodeld'
    
    sp.dependency 'KalturaPlayer/Core'
    sp.dependency 'PlayKitProviders', '~> 1.19'
    sp.dependency 'PlayKitKava', '~> 1.11'
  end
  
  ################################################################
  
  ###             Offline Supported only in iOS                ###
  ################################################################
  
  s.subspec 'Offline' do |sp|
    sp.ios.deployment_target = '15.0'
    
    sp.source_files = 'Sources/Offline/*', 'Sources/*', 'Sources/Basic/*', 'Sources/Interceptor/*', 'Sources/Playlist/*'
    
    sp.dependency 'DownloadToGo', '~> 3.20.0'
    sp.dependency 'PlayKit', '~> 3.31'
  end
  
   s.subspec 'Offline_OTT' do |sp|
    sp.ios.deployment_target = '15.0'
    
    sp.source_files =  'Sources/Offline/OTT/*', 'Sources/OTT/*', 'Sources/Common'
    sp.resources = 'Sources/OTT/*.xcdatamodeld'
    
    sp.dependency 'KalturaPlayer/Offline'
    sp.dependency 'PlayKitProviders', '~> 1.19'
    sp.dependency 'PlayKitKava', '~> 1.11'
  end
  
  s.subspec 'Offline_OVP' do |sp|
    sp.ios.deployment_target = '15.0'
    
    sp.source_files =  'Sources/Offline/OVP/*', 'Sources/OVP/*', 'Sources/Common'
    sp.resources = 'Sources/OVP/*.xcdatamodeld'
    
    sp.dependency 'KalturaPlayer/Offline'
    sp.dependency 'PlayKitProviders', '~> 1.19'
    sp.dependency 'PlayKitKava', '~> 1.11'
  end
  
  ################################################################
  ###                        UI for iOS                        ###
  ################################################################
  
  s.subspec 'UI' do |sp|
    sp.ios.deployment_target = '15.0'
    
    sp.source_files = 'Sources/UI/*'
    sp.resources = [ 'Sources/UI/Assets/*']
    
    sp.dependency 'KalturaPlayer/Core'
  end
 
  ################################################################
  
  s.default_subspec = 'Core'
end
