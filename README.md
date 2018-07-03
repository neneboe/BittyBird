# BittyBird

[![CI Status](https://img.shields.io/travis/neneboe/BittyBird.svg?style=flat)](https://travis-ci.org/neneboe/BittyBird)
[![Version](https://img.shields.io/cocoapods/v/BittyBird.svg?style=flat)](https://cocoapods.org/pods/BittyBird)
[![License](https://img.shields.io/cocoapods/l/BittyBird.svg?style=flat)](https://cocoapods.org/pods/BittyBird)
[![Platform](https://img.shields.io/cocoapods/p/BittyBird.svg?style=flat)](https://cocoapods.org/pods/BittyBird)

BittyBird is still a work in progress. When done, the final implementation will be as close as possible to the official [Phoenix Channels Javascript client](https://github.com/phoenixframework/phoenix/blob/master/assets/js/phoenix.js). So close in fact that you can basically use their documentation from that client to figure everything out with this one.

## Requirements

BittyBird was written using Swift 4.1.2 targeted at devices using iOS 8.0 and above. It's only dependency is [SwiftMsgPack](https://github.com/malcommac/SwiftMsgPack), which it uses for its MessagePack implementaion.

## Installation
BittyBird is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BittyBird'
```

## Testing

To run the tests, clone the repo, run `pod install` from the Example directory, then tests should pass.

## About

#### API Differences from Phoenix JS Client

  * `BBTimer` instead of `Timer`
  * `Socket.socketProtocol` instead of `Socket.protocol`
  * `Socket.heartbeatIntervalSeconds` instead of `Socket.heartbeatIntervalMs`
  * `Socket.reconnectAfterSeconds` instead of `Socket.reconnectAfterMs`
  * `skipHeartbeat` is a property of `Socket` instead of `Socket.connection`
  * No `Socket.connectionState` method. Starscream doesn't yet support this.
  * `Socket.push` takes an instance of `Message` as a param instead of a generic data object

#### Author

Nick Eneboe - Shout out to SwiftPhoenixClient though. This repo is very nearly a fork of SwiftPhoenixClient, but I wanted to write it from scratch for my own practice.

#### License

BittyBird is available under the MIT license. See the LICENSE file for more info.
