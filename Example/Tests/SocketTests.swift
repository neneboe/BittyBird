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

class MockWebSocket: WebSocket {
  var disconnectCalled = false
  override func disconnect(forceTimeout: TimeInterval? = nil, closeCode: UInt16 = 1000) {
    disconnectCalled = true
  }
  var connectCalled = false
  override func connect() { connectCalled = true }
}

class SocketSpec: QuickSpec {
  override func spec() {
    describe("A Socket") {
      let wsEndPoint = "ws://localhost:4000/socket/websocket"
      let wssEndPoint = "wss://localhost:4000/socket/websocket"
      var wsSocket = Socket(endPoint: wsEndPoint)
      var wssSocket = Socket(endPoint: wssEndPoint)
      var mockConnection = MockWebSocket(url: URL(string: wsEndPoint)!)
      var mockSocket = Socket(connection: mockConnection)

      beforeEach {
        wsSocket = Socket(endPoint: wsEndPoint)
        wssSocket = Socket(endPoint: wssEndPoint)
        mockConnection = MockWebSocket(url: URL(string: wsEndPoint)!)
        mockSocket = Socket(connection: mockConnection)
      }

      describe("initializer") {
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

      describe("computed properties") {
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
    }
  }
}
