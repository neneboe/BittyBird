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
  override var isConnected: Bool { get { return true }}

  var pushCalled = false
  override func push(msg: Message) {
    pushCalled = true
    super.push(msg: msg)
  }
}

class MockChannel: Channel {
  var triggerTimesCalled = 0
  var triggerMsg = Message()
  var triggerCalled: Bool { get { return triggerTimesCalled > 0 }}
  override func trigger(msg: Message) {
    triggerTimesCalled += 1
    triggerMsg = msg
    super.trigger(msg: msg)
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

class MockPush: Push {
  var startTimeoutCalled = false
  override func startTimeout() {
    startTimeoutCalled = true
  }

  var sendCalled = false
  override func send() {
    sendCalled = true
  }

  var receivedStatuses: Array <String> = []
  override func receive(status: String, callback: ((Message) -> Void)) -> Push {
    let testMsg = Message(
      topic: "mock:push", event: "receive", payload: ["status": status], ref: "r", joinRef: "jr"
    )
    receivedStatuses.append(status)
    callback(testMsg)
    return self
  }

  var triggerCalled = false
  var triggerStatus = ""
  override func trigger(status: String, payload: Dictionary<String, Any>) {
    triggerCalled = true
    triggerStatus = status
    super.trigger(status: status, payload: payload)
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