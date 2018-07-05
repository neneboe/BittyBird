//
//  SocketTests.swift
//  BittyBird_Tests
//
//  Created by Nick Eneboe on 6/29/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import Starscream
@testable import BittyBird

class SocketSpec: QuickSpec {
  @objc func timerStub() {
    ()
  }
  
  override func spec() {
    describe("A Socket") {
      let wsEndPoint = "ws://localhost:4000/socket/websocket"
      let wssEndPoint = "wss://localhost:4000/socket/websocket"
      let testMsg = Message(
        topic: "room:lobby", event: "pushTest", payload: ["a": "b"], ref: "r", joinRef: "jr"
      )

      // ********************************************************** //
      /// These are all reset in the beforeEach block
      var callback1Triggered = false
      var callback2Triggered = false
      var logKind = ""
      var logMsg = ""
      var logData = "" as Any
      var wsSocket = Socket(endPoint: wsEndPoint)
      var wssSocket = Socket(endPoint: wssEndPoint)
      var mockChannel = MockChannel(topic: "topic", params: ["k": "v"], socket: wsSocket)
      var mockConnection = MockConnection(url: URL(string: wsEndPoint)!)
      var mockSocket = Socket(connection: mockConnection)
      var mockSerializer = MockSerializer()
      var mockConnectedSocketOptions = SocketOptions()
      var mockConnectedSocket = MockConnectedSocket(connection: mockConnection)
      var testTimer: Timer?
      // ********************************************************** //

      let callback1 = { () -> Void in callback1Triggered = true }
      let callback2 = { () -> Void in callback2Triggered = true }

      beforeEach {
        callback1Triggered = false
        callback2Triggered = false
        logKind = ""
        logMsg = ""
        logData = "" as Any
        wsSocket = Socket(endPoint: wsEndPoint)
        wssSocket = Socket(endPoint: wssEndPoint)
        mockConnection = MockConnection(url: URL(string: wsEndPoint)!)
        mockSocket = Socket(connection: mockConnection)
        mockSerializer = MockSerializer()
        mockConnectedSocketOptions = SocketOptions(
          logger: { (_ kind, _ msg, _ data) in
            logKind = kind
            logMsg = msg
            logData = data
        },
          serializer: mockSerializer
        )
        mockConnectedSocket = MockConnectedSocket(connection: mockConnection, opts: mockConnectedSocketOptions)
        mockChannel = MockChannel(topic: "test:room", params: ["k": "v"], socket: wsSocket)
        testTimer = Timer.scheduledTimer(
          timeInterval: 5,
          target: self,
          selector: #selector(self.timerStub),
          userInfo: nil,
          repeats: false
        )
      }

      afterEach {
        testTimer!.invalidate()
      }

      describe("initializer") {
        // TODO: Check for more properties
        it("sets the correct property names") {
          expect(wsSocket.timeout).notTo(beNil())
          expect(wsSocket.reconnectAfterSeconds).notTo(beNil())
        }

        it("accepts an instance of SocketOptions") {
          var loggerHasRun = false
          let socketOptions = SocketOptions(
            timeout: 999,
            heartbeatIntervalSeconds: 998,
            reconnectAfterSeconds: {(_ sec) -> Int in return 997},
            logger: { (_ kind, _ msg, _ data) in loggerHasRun = true },
            params: ["param1": "value1", "param2": "value2"]
          )
          let configuredSocket = Socket(endPoint: wsEndPoint, opts: socketOptions)
          configuredSocket.log(kind: "kind", msg: "msg", data: "data")
          expect(configuredSocket.timeout) == 999
          expect(configuredSocket.heartbeatIntervalSeconds) == 998
          expect(configuredSocket.reconnectAfterSeconds(1)) == 997
          expect(configuredSocket.params["param1"] as? String) == "value1"
          expect(configuredSocket.params["param2"] as? String) == "value2"
          expect(loggerHasRun).to(beTrue())
        }

        describe("`endPointURL`") {
          context("when there are no `params`") {
            it("sets the URL endPoint with only vsn as a param") {
              let urlWithVersion = wsEndPoint + "?vsn=" + Socket.VSN
              expect(wsSocket.endPointURL) == URL(string: urlWithVersion)!
            }
          }

          context("when there are `params`") {
            it("sets the URL endpoint with `params` and version as params") {
              let socketOptions = SocketOptions(params: ["foo": "bar", "baz": "buzz"])
              let configuredSocket = Socket(endPoint: wsEndPoint, opts: socketOptions)
              let urlComponents = URLComponents(url: configuredSocket.endPointURL, resolvingAgainstBaseURL: false)!
              let params = urlComponents.queryItems!
              expect(params.first(where: { $0.name == "foo" })!.value) == "bar"
              expect(params.first(where: { $0.name == "baz" })!.value) == "buzz"
              expect(params.first(where: { $0.name == "vsn" })!.value) == Socket.VSN
            }
          }
        }
      }

      describe("`socketProtocol`") {
        context("when endpoint protocol is wss") {
          it("returns the string 'wss'") {
            expect(wssSocket.socketProtocol) == "wss"
          }
        }
        context("when endpoint protocol is ws") {
          it("returns the string 'ws'") {
            expect(wsSocket.socketProtocol) == "ws"
          }
        }
      }

      describe(".disconnect") {
        it("calls disconnect on `connection`") {
          precondition(mockConnection.disconnectCalled == false)
          mockSocket.disconnect()
          expect(mockConnection.disconnectCalled).to(beTrue())
        }

        it("resets `connection.delegate` to nil") {
          mockConnection.delegate = mockSocket
          precondition(mockConnection.delegate != nil)
          mockSocket.disconnect()
          expect(mockConnection.delegate).to(beNil())
        }

        it("triggers the callback if one is passed") {
          var callbackTriggered = false
          mockSocket.disconnect() { () -> Void in callbackTriggered = true }
          expect(callbackTriggered).to(beTrue())
        }
      }

      describe(".connect") {
        it("calls connect on `connection`") {
          precondition(mockConnection.connectCalled == false)
          mockSocket.connect()
          expect(mockConnection.connectCalled).to(beTrue())
        }

        it("sets `connection.delete` to socket") {
          precondition(mockConnection.delegate == nil)
          mockSocket.connect()
          expect(mockConnection.delegate).toNot(beNil())
        }
      }

      describe(".log") {
        it("triggers the `logger` property") {
          mockConnectedSocket.log(kind: "kind", msg: "msg", data: "data")
          expect(logKind) == "kind"
        }
      }

      describe("methods to register callbacks on state change events") {
        let eventCallback = { () -> Void in () }
        
        describe(".onOpen") {
          it("adds passed in callback to `stateChangeCallbacks.open`") {
            precondition(wsSocket.stateChangeCallbacks.open.count == 0)
            wsSocket.onOpen(callback: eventCallback)
            expect(wsSocket.stateChangeCallbacks.open.count) == 1
          }
        }
        describe(".onClose") {
          it("adds passed in callback to `stateChangeCallbacks.close`") {
            precondition(wsSocket.stateChangeCallbacks.close.count == 0)
            wsSocket.onClose(callback: eventCallback)
            expect(wsSocket.stateChangeCallbacks.close.count) == 1
          }
        }
        describe(".onError") {
          it("adds passed in callback to `stateChangeCallbacks.error`") {
            precondition(wsSocket.stateChangeCallbacks.error.count == 0)
            wsSocket.onError(callback: eventCallback)
            expect(wsSocket.stateChangeCallbacks.error.count) == 1
          }
        }
        describe(".onMessage") {
          it("adds passed in callback to `stateChangeCallbacks.message`") {
            precondition(wsSocket.stateChangeCallbacks.message.count == 0)
            wsSocket.onMessage(callback: eventCallback)
            expect(wsSocket.stateChangeCallbacks.message.count) == 1
          }
        }
      }

      describe(".onConnOpen") {
        it("logs an open message") {
          mockConnectedSocket.onConnOpen()
          expect(logKind) == "transport"
          expect(logMsg) == "Connected to \(mockConnectedSocket.connection.currentURL)"
        }

        it("flushes the send buffer") {
          var sendBufferFlushed = false
          mockConnectedSocket.sendBuffer.append() { () -> Void in sendBufferFlushed = true }
          mockConnectedSocket.onConnOpen()
          expect(sendBufferFlushed).to(beTrue())
        }

        it("clears `reconnectTimer`") {
          wsSocket.reconnectTimer.scheduleTimeout()
          precondition(wsSocket.reconnectTimer.timer!.isValid)
          wsSocket.onConnOpen()
          expect(wsSocket.reconnectTimer.timer).to(beNil())
        }

        context("when `skipHeartbeat` is false") {
          beforeEach {
            precondition(wsSocket.skipHeartbeat == false)
          }

          it("clears existing `heartbeatTimer`") {
            let existingTimer = testTimer!
            wsSocket.heartbeatTimer = existingTimer
            precondition(existingTimer.isValid)
            wsSocket.onConnOpen()
            expect(existingTimer.isValid).to(beFalse())
            expect(wsSocket.heartbeatTimer) != existingTimer
          }
          it("sets and starts `heartbeatTimer`") {
            wsSocket.onConnOpen()
            expect(wsSocket.heartbeatTimer!.isValid).to(beTrue())
          }
        }

        context("when `skipHeartbeat is true") {
          it("doesn't set `heartbeatTimer`") {
            wsSocket.skipHeartbeat = true
            wsSocket.onConnOpen()
            expect(wsSocket.heartbeatTimer).to(beNil())
          }
        }

        it("triggers each callback in `stateChangeCallbacks.open`") {
          wsSocket.stateChangeCallbacks.open = [callback1, callback2]
          wsSocket.onConnOpen()
          expect(callback1Triggered).to(beTrue())
          expect(callback2Triggered).to(beTrue())
        }
      }

      describe(".onConnClose") {
        it("logs a close message") {
          mockConnectedSocket.onConnClose()
          expect(logKind) == "transport"
          expect(logMsg) == "close"
        }

        it("triggers errors in socket channels") {
          wsSocket.channels = [mockChannel]
          wsSocket.onConnClose()
          expect(mockChannel.triggerCalled).to(beTrue())
        }

        it("clears `heartbeatTimer`") {
          wsSocket.heartbeatTimer = testTimer!
          wsSocket.onConnClose()
          expect(wsSocket.heartbeatTimer?.isValid).to(beFalse())
        }

        it("starts the `reconnectTimer`") {
          precondition(wsSocket.reconnectTimer.timer == nil)
          wsSocket.onConnClose()
          expect(wsSocket.reconnectTimer.timer?.isValid).to(beTrue())
        }

        it("triggers each callback in `stateChangeCallbacks.close`") {
          wsSocket.stateChangeCallbacks.close = [callback1, callback2]
          wsSocket.onConnClose()
          expect(callback1Triggered).to(beTrue())
          expect(callback2Triggered).to(beTrue())
        }
      }

      describe(".onConnError") {
        it("logs an error message") {
          mockConnectedSocket.onConnError(error: "the error msg")
          expect(logKind) == "transport"
          expect(logMsg) == "error"
          expect(logData as? String) == "the error msg"
        }

        it("triggers errors in socket channels") {
          wsSocket.channels = [mockChannel]
          wsSocket.onConnError(error: "error")
          expect(mockChannel.triggerCalled).to(beTrue())
        }

        it("triggers each callback in `stateChangeCallbacks.error`") {
          wsSocket.stateChangeCallbacks.error = [callback1, callback2]
          wsSocket.onConnError(error: "error")
          expect(callback1Triggered).to(beTrue())
          expect(callback2Triggered).to(beTrue())
        }
      }

      describe(".triggerChanError") {
        it("sends an error message to socket's channels") {
          wsSocket.channels = [mockChannel]
          wsSocket.onConnError(error: "error")
          expect(mockChannel.triggerCalled).to(beTrue())
          expect(mockChannel.triggerMsg.event) == "error"
        }
      }

      describe("`isConnected`") {
        it("returns `connection.isConnected`") {
          expect(wsSocket.isConnected) == wsSocket.connection.isConnected
        }
      }

      describe(".remove") {
        // TODO
        xit("removes channel from `channels`") {
          
        }
      }

      describe(".channel") {
        it("creates a new channel with params") {
          let testChan = wsSocket.channel(topic: "chan:test1", chanParams: ["c": "p"])
          expect(testChan.topic) == "chan:test1"
          expect(testChan.params["c"] as? String) == "p"
          expect(testChan.socket.endPointURL) == wsSocket.endPointURL
        }

        it("adds channel to `channels`") {
          let testChan = wsSocket.channel(topic: "chan:test2", chanParams: ["c": "p"])
          expect(wsSocket.channels.first!) === testChan
        }
      }

      describe(".push") {
        it("logs a push message") {
          mockConnectedSocket.push(msg: testMsg)
          expect(logKind) == "push"
          expect(logMsg) == "room:lobby pushTest (jr, r)"
          var data = logData as? Dictionary <String, Any>
          expect(data!["a"] as? String) == "b"
        }

        context("when socket is connected") {
          it("triggers the callback immediately") {
            mockConnectedSocket.push(msg: testMsg)
            expect(mockSerializer.encodeCalled).to(beTrue())
          }
        }

        context("when socket is not connected") {
          it("appends callback to `sendBuffer`") {
            precondition(wsSocket.sendBuffer.count == 0)
            wsSocket.push(msg: testMsg)
            expect(wsSocket.sendBuffer.count) == 1
          }
        }
      }

      describe(".makeRef") {
        it("returns an incrementing ref string") {
          expect(wsSocket.makeRef()) == "1"
          expect(wsSocket.makeRef()) == "2"
        }

        it("returns '0' if ref overflows") {
          wsSocket.ref = UInt64.max - 1
          expect(wsSocket.makeRef()) == "\(UInt64.max)"
          expect(wsSocket.makeRef()) == "1"
        }
      }

      describe(".sendHeartbeat") {
        context("when socket is not connected") {
          it("does nothing") {
            precondition(wsSocket.isConnected == false)
            wsSocket.pendingHeartbeatRef = "someRef"
            wsSocket.sendHeartbeat() // would reset `pendingHeartbeatRef` to nil if connected
            expect(wsSocket.pendingHeartbeatRef) == "someRef"
          }
        }

        context("when socket is connected") {
          context("when there is no `pendingHeartbeatRef`") {
            it("sets `pendingHeartbeatRef` to new ref") {
              precondition(mockConnectedSocket.pendingHeartbeatRef == nil)
              mockConnectedSocket.sendHeartbeat()
              expect(mockConnectedSocket.pendingHeartbeatRef).toNot(beNil())
            }

            it("pushes a heartbeat message to server") {
              precondition(mockSerializer.encodeCalled == false)
              mockConnectedSocket.sendHeartbeat()
              expect(mockSerializer.encodeCalled).to(beTrue())
            }
          }
          context("when there is a `pendingHeartbeatRef`") {
            beforeEach {
              mockConnectedSocket.pendingHeartbeatRef = "pendingRef"
            }

            it("resets `pendingHeartbeatRef`") {
              mockConnectedSocket.sendHeartbeat()
              expect(mockConnectedSocket.pendingHeartbeatRef).to(beNil())
            }

            it("logs a heartbeat timeout message") {
              mockConnectedSocket.sendHeartbeat()
              expect(logKind) == "transport"
              expect(logMsg) == "Heartbeat timeout. Attempting to re-establish connection..."
            }

            it("calls `disconnect` on socket") {
              precondition(mockConnection.disconnectCalled == false)
              mockConnectedSocket.sendHeartbeat()
              expect(mockConnection.disconnectCalled).to(beTrue())
            }
          }
        }
      }

      describe(".flushSendBuffer") {
        it("triggers each callback in `sendBuffer`") {
          mockConnectedSocket.sendBuffer = [callback1, callback2]
          mockConnectedSocket.flushSendBuffer()
          expect(callback1Triggered).to(beTrue())
          expect(callback2Triggered).to(beTrue())
        }

        it("resets `sendBuffer` to empty") {
          mockConnectedSocket.sendBuffer = [callback1, callback2]
          mockConnectedSocket.flushSendBuffer()
          expect(mockConnectedSocket.sendBuffer.count) == 0
        }
      }

      describe(".onConnMessage") {
        var data = Data()

        beforeEach {
          data = Data()
          try! data.pack(
            [
              "topic": testMsg.topic,
              "event": testMsg.event,
              "payload": testMsg.payload,
              "ref": testMsg.ref,
              "joinRef": testMsg.joinRef as Any
            ]
          )
        }
        it("decodes the message") {
          mockConnectedSocket.onConnMessage(rawMessage: data)
          expect(mockSerializer.decodeCalled).to(beTrue())
        }

        it("logs a received message") {
          mockConnectedSocket.onConnMessage(rawMessage: data)
          expect(logKind) == "receive"
          expect(logMsg) == " room:lobby pushTest r"
          var ld = logData as! Dictionary <String, Any>
          expect(ld["a"] as? String) == testMsg.payload["a"] as? String
        }

        it("sends message to member channels") {
          mockConnectedSocket.channels = [mockChannel]
          mockConnectedSocket.onConnMessage(rawMessage: data)
          expect(mockChannel.triggerCalled).to(beTrue())
        }

        it("triggers callbacks in `stateChangeCallbacks.message`") {
          mockConnectedSocket.stateChangeCallbacks.message = [callback1, callback2]
          mockConnectedSocket.onConnMessage(rawMessage: data)
          expect(callback1Triggered).to(beTrue())
          expect(callback2Triggered).to(beTrue())
        }

        context("when message is reply to heartbeat") {
          beforeEach {
            mockConnectedSocket.pendingHeartbeatRef = testMsg.ref
          }

          it("logs pending heartbeat received") {
            mockConnectedSocket.onConnMessage(rawMessage: data)
            expect(logKind) == "transport"
            expect(logMsg) == "Received pending heartbeat"
          }

          it("resets `pendingHeartbeatRef`") {
            mockConnectedSocket.onConnMessage(rawMessage: data)
            expect(mockConnectedSocket.pendingHeartbeatRef).to(beNil())
          }
        }
      }
    }
  }
}
