# suffix = '.0000'   # Dev mode
suffix = ''       # Release


Pod::Spec.new do |s|
  
  s.name             = 'KalturaPlayer'
  s.version          = '4.6.0' + suffix
  s.summary          = 'KalturaPlayer -- Kaltura Player for iOS and tvOS'
  s.homepage         = 'https://github.com/kaltura/kaltura-player-ios'
  s.license          = { :type => 'AGPLv3', :file => 'LICENSE' }
  s.author           = { 'Kaltura' => 'community@kaltura.com' }
  s.source           = { :git => 'https://github.com/kaltura/kaltura-player-ios.git', :tag => 'v' + s.version.to_s }
  s.swift_version    = '5.0'
  
  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'
  
  s.subspec 'Interceptor' do |sp|
    sp.source_files = 'Sources/Interceptor/*'
    
    sp.dependency 'PlayKit', '~> 3.25'
  end
  
  s.xcconfig = {
    ### The following is required for Xcode 12 (https://stackoverflow.com/questions/63607158/xcode-12-building-for-ios-simulator-but-linking-in-object-file-built-for-ios)
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  
  ################################################################
  
  s.subspec 'Core' do |sp|
    sp.ios.deployment_target = '10.0'
    sp.tvos.deployment_target = '10.0'
    
    sp.source_files = 'Sources/*', 'Sources/Basic/*', 'Sources/Playlist/*'
    
    sp.dependency 'KalturaPlayer/Interceptor'
  end
  
  s.subspec 'OTT' do |sp|
    sp.source_files = 'Sources/OTT/*', 'Sources/Common'
    sp.resources = 'Sources/OTT/*.xcdatamodeld'
    
    sp.dependency 'KalturaPlayer/Core'
    sp.dependency 'PlayKitProviders', '~> 1.16'
    sp.dependency 'PlayKitKava', '~> 1.8'
  end
  
  s.subspec 'OVP' do |sp|
    sp.source_files = 'Sources/OVP/*', 'Sources/Common'
    sp.resources = 'Sources/OVP/*.xcdatamodeld'
    
    sp.dependency 'KalturaPlayer/Core'
    sp.dependency 'PlayKitProviders', '~> 1.16'
    sp.dependency 'PlayKitKava', '~> 1.8'
  end
  
  ################################################################
  ###             Offline Supported only in iOS                ###
  ################################################################
  
  s.subspec 'Offline' do |sp|
    sp.ios.deployment_target = '10.0'
    
    sp.source_files = 'Sources/Offline/*', 'Sources/*', 'Sources/Basic/*', 'Sources/Interceptor/*', 'Sources/Playlist/*'
    
    sp.dependency 'DownloadToGo', '~> 3.17'
    sp.dependency 'PlayKit', '~> 3.25'
    
    sp.xcconfig = {
      ### The following is required for Xcode 12 (https://stackoverflow.com/questions/63607158/xcode-12-building-for-ios-simulator-but-linking-in-object-file-built-for-ios)
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    
  end
  
  s.subspec 'Offline_OTT' do |sp|
    sp.ios.deployment_target = '10.0'
    
    sp.source_files =  'Sources/Offline/OTT/*', 'Sources/OTT/*', 'Sources/Common'
    sp.resources = 'Sources/OTT/*.xcdatamodeld'
    
    sp.dependency 'KalturaPlayer/Offline'
    sp.dependency 'PlayKitProviders', '~> 1.16'
    sp.dependency 'PlayKitKava', '~> 1.8'
    
    sp.xcconfig = {
      ### The following is required for Xcode 12 (https://stackoverflow.com/questions/63607158/xcode-12-building-for-ios-simulator-but-linking-in-object-file-built-for-ios)
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    
  end
  
  s.subspec 'Offline_OVP' do |sp|
    sp.ios.deployment_target = '10.0'
    
    sp.source_files =  'Sources/Offline/OVP/*', 'Sources/OVP/*', 'Sources/Common'
    sp.resources = 'Sources/OVP/*.xcdatamodeld'
    
    sp.dependency 'KalturaPlayer/Offline'
    sp.dependency 'PlayKitProviders', '~> 1.16'
    sp.dependency 'PlayKitKava', '~> 1.8'
    
    sp.xcconfig = {
      ### The following is required for Xcode 12 (https://stackoverflow.com/questions/63607158/xcode-12-building-for-ios-simulator-but-linking-in-object-file-built-for-ios)
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    
  end
  
  ################################################################
  ###                        UI for iOS                        ###
  ################################################################
  
  s.subspec 'UI' do |sp|
    sp.ios.deployment_target = '10.0'
    
    sp.source_files = 'Sources/UI/*'
    sp.resources = [ 'Sources/UI/Assets/*']
    
    sp.dependency 'KalturaPlayer/Core'
    
  end
  
  ################################################################
  
  s.default_subspec = 'Core'
end
