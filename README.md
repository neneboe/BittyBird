# BittyBird

[![CI Status](https://img.shields.io/travis/neneboe/BittyBird.svg?style=flat)](https://travis-ci.org/neneboe/BittyBird)
[![Version](https://img.shields.io/cocoapods/v/BittyBird.svg?style=flat)](https://cocoapods.org/pods/BittyBird)
[![License](https://img.shields.io/cocoapods/l/BittyBird.svg?style=flat)](https://cocoapods.org/pods/BittyBird)
[![Platform](https://img.shields.io/cocoapods/p/BittyBird.svg?style=flat)](https://cocoapods.org/pods/BittyBird)

BittyBird is a Swift client library for interacting with Phoenix Channels. It defaults to using JSON for serialization, but also comes with a MessagePack serializer for encoding and decoding messages to/from binary. Check out this blog post on [how to set up your Phoenix app to use MessagePack for serialization](https://strongwing.studio/2018/07/07/setting-up-phoenix-channels-to-use-messagepack-for-serialization/).

## Installation
BittyBird is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BittyBird', '~> 0.0.2'
```

## Requirements

BittyBird was written for connecting to Phoenix apps versions >=1.3 using Swift 4.1.2 targeted at devices using iOS 8.0 and above. It's dependencies are [SwiftMsgPack](https://github.com/malcommac/SwiftMsgPack), which it uses for its MessagePack serialization, and [Starscream](https://github.com/daltoniam/Starscream), a Swift WebSocket library.

## Usage

##### Examples of Creating a Socket

```swift
// Production
let socket = Socket(endPoint: "wss://yoursite.com/socket/websocket")

// Development
let socket = Socket(endPoint: "ws://localhost:4000/socket/websocket")

// Use MessagePack for serialization
let socketOptions = SocketOptions(serializer: MsgPackSerializer())
let socket = Socket(endPoint: "wss://yoursite.com/socket/websocket", opts: socketOptions)

// More Options - All SocketOptions parameters are optional
let socketOptions = SocketOptions(
  timeout: 15, heartbeatIntervalSeconds: 60,
  reconnectAfterSeconds: { (tries: Int) -> Int in return 100 },
  logger: { (kind: String, msg: String, data: Any?) in
    print("kind: \(kind), msg: \(msg), data: \(data)")   
  },
  params: ["customParamKey": "customParamValue"],
  serializer: CustomSerializer() // Any class that conforms to Serializer protocol will work
)
let socket = Socket(endPoint: "wss://yoursite.com/socket/websocket", opts: socketOptions)
```

##### Examples of Creating and Joining Channels
  
```swift
// Creating a channel without parameters
let channel = socket.channel(topic: "room:lobby")

// Creating a channel with parameters, passed to Phoenix channel's join function
let channel = socket.channel(topic: "room:lobby", chanParams: ["customParam": "customValue"])

// Joining a channel
channel.join()
  .receive(status: "ok") { (msg) in /* handle successful join */ }
  .receive(status: "error") { (errorMsg) in /* handle error */ }
  .receive(status: "timeout") { (_) in /* handle timeout */ }
```

##### Examples of Pushing and Handling Events

```swift
// Handling events
channel.on(event: "someEvent") { (msg) in
  /* Handle "someEvent" message, probably doing something with msg.payload */ 
}

// Pushing messages
channel.push(event: "somePushEvent", payload: ["aKey": "aValue", "anotherKey": "anotherValue"])

// Pushing messages and optionally receiving replys
channel.push(event: "somePushEvent", payload: ["aKey": "aValue"])
  .receive(status: "ok") { (msg) in /* handle push reply */ }
  .receive(status: "error") { (errorMsg) in /* handle push error */ }
  .receive(status: "timeout") { (_) in /* handle push timeout */ }
```

## About

The main goal of BittyBird was to be as close to the [Phoenix JS client](https://github.com/phoenixframework/phoenix/blob/master/assets/js/phoenix.js) as possible. I also tried to keep it as customizable as possible. This means almost all classes and functions are open, so you can override them with your own implementations if you want to. Just be careful.

#### Notable API Differences from Phoenix JS Client

  * All params are named params
  * `BBTimer` instead of `Timer`
  * `Socket.socketProtocol` instead of `Socket.protocol`
  * `Socket.heartbeatIntervalSeconds` instead of `Socket.heartbeatIntervalMs`
  * `Socket.reconnectAfterSeconds` instead of `Socket.reconnectAfterMs`
  * `skipHeartbeat` is a property of `Socket` instead of `Socket.connection`
  * No `Socket.connectionState` method. Starscream doesn't yet support this.
  * The Phoenix JS client passes messages around either as a generic data object with `topic`, `payload`, etc. properies, or as individual parameters, e.g. the `Channel.isMemeber` method. BittyBird replaces both these patterns by passing around an instance of a `Message` type.
  * `Channel.init` takes an optional `pushClass` param, which defaults to `Push.self`. Used here as a way of adding dependency injection for testing, but you could swap in any Push subclass implementation using this param. I'll probably remove this param in a future version if Swift ever adapts default vaules for generics.

#### Author

BittyBird was written by Nick Eneboe. Credit to [SwiftPhoenixClient](https://github.com/davidstump/SwiftPhoenixClient), from which this repo borrows a lot. Also credit to the Phoenix Framework contributors for the API design of [phoenix.js](https://github.com/phoenixframework/phoenix/blob/master/assets/js/phoenix.js).

## Developing

To setup BittyBird for development on your machine:

  1. Clone the repo
  2. In a terminal, cd to the BittyBird/Example directory
  3. Run `pod install`
  4. Open BittyBird/Example/BittyBird.xcworkspace in Xcode
  5. Type ⌘+U to run the tests and make sure all the tests pass.

## License

BittyBird is available under the MIT license. See the LICENSE file for more info.
