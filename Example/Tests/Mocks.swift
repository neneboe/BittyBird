//
//  Mocks.swift
//  BittyBird_Tests
//
//  Created by Nick Eneboe on 7/4/18.
//

import Starscream
@testable import BittyBird

class MockConnection: BBStarscreamSocket {
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
  var triggerCalled: Bool { return triggerTimesCalled > 0 }
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

  var sendJoinTimeoutPassed = -1
  override func sendJoin(timeout: Int) {
    sendJoinTimeoutPassed = timeout
    super.sendJoin(timeout: timeout)
  }

  var createAndSendLeavePushCalled = false
  override func createAndSendLeavePush() -> Push {
    createAndSendLeavePushCalled = true
    return super.createAndSendLeavePush()
  }

  var offCalledWith = ""
  var offCalled: Bool { return offCalledWith != "" }
  override func off(event: String) {
    offCalledWith = event
    super.off(event: event)
  }
}


class MockPush: Push {
  var startTimeoutCalled = false
  override func startTimeout() {
    startTimeoutCalled = true
    super.startTimeout()
  }

  var cancelTimeoutCalled = false
  override func cancelTimeout() {
    cancelTimeoutCalled = true
    super.cancelTimeout()
  }

  var sendCalled = false
  override func send() {
    sendCalled = true
  }

  var receivedBindings: [(status: String, callback: (Message) -> Void)] = []
  override func receive(status: String, callback: @escaping ((Message) -> Void)) -> Push {
    receivedBindings.append((status: status, callback: callback))
    super.receive(status: status, callback: callback)
    return self
  }

  var resendCalled = false
  override func resend(timeout: Int) {
    resendCalled = true
    super.resend(timeout: timeout)
  }

  var triggerCalled = false
  var triggerStatus = ""
  override func trigger(status: String, payload: Dictionary<String, Any>) {
    triggerCalled = true
    triggerStatus = status
    super.trigger(status: status, payload: payload)
  }

  var resetCalled = false
  override func reset() {
    resetCalled = true
    super.reset()
  }

  var cancelRefEventCalled = false
  override func cancelRefEvent() {
    cancelRefEventCalled = true
    super.cancelRefEvent()
  }

  var matchReceiveCalled = false
  override func matchReceive(status: String, msg: Message) {
    matchReceiveCalled = true
    super.matchReceive(status: status, msg: msg)
  }
}



class MockMsgPackSerializer: MsgPackSerializer {
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
class MockJSONSerializer: JSONSerializer {
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
