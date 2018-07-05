//
//  Mocks.swift
//  BittyBird_Tests
//
//  Created by Nick Eneboe on 7/4/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Starscream
@testable import BittyBird

class MockConnection: WebSocket {
  var disconnectCalled = false
  override func disconnect(forceTimeout: TimeInterval? = nil, closeCode: UInt16 = 1000) {
    disconnectCalled = true
  }
  var connectCalled = false
  override func connect() { connectCalled = true }
}

class MockConnectedSocket: Socket {
  override var isConnected: Bool {
    get {
      return true
    }
  }
}

class MockChannel: Channel {
  var triggerCalled = false
  var triggerMsg = Message()
  override func trigger(msg: Message) {
    triggerCalled = true
    triggerMsg = msg
  }

  override func isMember(msg: Message) -> Bool {
    return true
  }

  var rejoinCalled = false
  override func rejoin(timeout: Int? = nil) {
    rejoinCalled = true
    super.rejoin(timeout: timeout)
  }
}

class MockSerializer: Serializer {
  var encodeCalled = false
  override func encode(msg: Message, callback: ((Data) -> Void)) {
    encodeCalled = true
  }

  var decodeCalled = false
  override func decode(rawPayload: Data, callback: ((Message) -> Void)) {
    decodeCalled = true
    super.decode(rawPayload: rawPayload, callback: callback)
  }
}
