# KalturaPlayer

## Getting Started

To integrate KalturaPlayer into your Xcode project, specify it in your `Podfile`:

```ruby
pod 'KalturaPlayer/OVP'
```
or
```ruby
pod KalturaPlayer/OTT
```
according to your backend. In case you like to add basic UI controls to your player, specify as well:
```ruby
pod 'KalturaPlayer/UI'
```

## Using in the application
- OTT
```swift
PlayerConfigManager.shared.retrieve(by: {UIConf ID}, baseUrl: '{OVP Base Server Url}', partnerId: {OVP Partner ID}, ks: '{KS}') { (uiConf, error) in
  var playerOptions = KalturaPlayerOptions(partnerId: {OTT Partner ID})
  playerOptions.serverUrl = '{OTT Base Server Url}'
  playerOptions.autoPlay = true //the play will start automatically
  playerOptions.uiManager = DefaultKalturaUIMananger() //use basic UI controls
  playerOptions.uiConf = uiConf
        
  self.player = KalturaPhoenixPlayer.create(with: playerOptions)
        
  let mediaOptions = PhoenixMediaOptions(assetId: '{Asset ID}', fileIds: ['{File ID}'])
  self.player?.loadMedia(mediaOptions: mediaOptions)
}
```
- OVP
```swift
PlayerConfigManager.shared.retrieve(by: {UIConf ID}, baseUrl: '{OVP Base Server Url}', partnerId: {OVP Partner ID}, ks: '{KS}') { (uiConf, error) in
  var playerOptions = KalturaPlayerOptions(partnerId: {OVP Partner ID})
  playerOptions.serverUrl = '{OVP Base Server Url}'
  playerOptions.autoPlay = true //the play will start automatically
  playerOptions.uiManager = DefaultKalturaUIMananger() //use basic UI controls
  playerOptions.uiConf = uiConf
            
  self.player = KalturaOvpPlayer.create(with: playerOptions)
            
  let mediaOptions = OVPMediaOptions(entryId: '{OVP Entry ID}')
  self.player?.loadMedia(mediaOptions: mediaOptions)
}
```
- Play on demand
```swift
PlayerConfigManager.shared.retrieve(by: {UIConf ID}, baseUrl: '{OVP Base Server Url}', partnerId: {OVP Partner ID}, ks: '{KS}') { (uiConf, error) in
  var playerOptions = KalturaPlayerOptions(partnerId: {OVP Partner ID})
  playerOptions.serverUrl = '{OVP Base Server Url}'
  playerOptions.preload = true
  playerOptions.uiConf = uiConf
            
  self.player = KalturaOvpPlayer.create(with: playerOptions)
            
  let mediaOptions = OVPMediaOptions(entryId: '{OVP Entry ID}')
  self.player?.loadMedia(mediaOptions: mediaOptions) { (entry, error) in
    //configure you UI
  }
}
```

## License and Copyright Information  

All code in this project is released under the [AGPLv3 license](http://www.gnu.org/licenses/agpl-3.0.html) unless a different license for a particular library is specified in the applicable library path.   

Copyright © Kaltura Inc. All rights reserved.   
Authors and contributors: See [GitHub contributors list](https://github.com/kaltura/playkit-ios-vr/graphs/contributors).
