//
//  ChannelTests.swift
//  BittyBird_Tests
//
//  Created by Nick Eneboe on 7/3/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Quick
import Nimble
@testable import BittyBird

class ChannelSpec: QuickSpec {
  override func spec() {
    describe("A Channel") {
      let endPoint = "ws://localhost:4000/socket/websocket"
      var unconnectedSocket = Socket(endPoint: endPoint)
      var unconnectedChannel = MockChannel(topic: "test:channel", socket: unconnectedSocket)
      var mockConnection = MockConnection(url: URL(string: endPoint)!)
      var mockConnectedSocket = MockConnectedSocket(connection: mockConnection)
      var mockChannel = MockChannel(topic: "test:topic", socket: mockConnectedSocket)

      beforeEach {
        unconnectedSocket = Socket(endPoint: endPoint)
        unconnectedChannel = MockChannel(topic: "test:channel", socket: unconnectedSocket)
        mockConnection = MockConnection(url: URL(string: endPoint)!)
        mockConnectedSocket = MockConnectedSocket(connection: mockConnection)
        mockChannel = MockChannel(topic: "test:topic", socket: mockConnectedSocket, pushClass: MockPush.self)
      }

      it("initializes") {
        // TODO add more expectations, maybe another context
        expect(unconnectedChannel.topic) == "test:channel"
      }

      describe(".rejoinUntilConnected") {
        it("starts the `rejoinTimer`") {
          precondition(unconnectedChannel.rejoinTimer?.timer == nil)
          unconnectedChannel.rejoinUntilConnected()
          expect(unconnectedChannel.rejoinTimer?.timer?.isValid).to(beTrue())
        }

        context("when socket is connected") {
          it("calls rejoin") {
            precondition(mockChannel.rejoinCalled == false && mockChannel.socket.isConnected)
            mockChannel.rejoinUntilConnected()
            expect(mockChannel.rejoinCalled).to(beTrue())
          }
        }

        context("when socket is not connected") {
          it("doesn't call rejoin") {
            precondition(
              unconnectedChannel.rejoinCalled == false &&
                unconnectedChannel.socket.isConnected == false
            )
            unconnectedChannel.rejoinUntilConnected()
            expect(unconnectedChannel.rejoinCalled).to(beFalse())
          }
        }
      }

      describe(".join") {
        it("flips `joinedOnce` switch") {
          precondition(unconnectedChannel.joinedOnce == false)
          let _ = unconnectedChannel.join()
          expect(unconnectedChannel.joinedOnce).to(beTrue())
        }

        it("calls `rejoin`") {
          let _ = unconnectedChannel.join()
          expect(unconnectedChannel.rejoinCalled).to(beTrue())
        }

        it("returns `joinPush`") {
          let joinPush = unconnectedChannel.join()
          expect(joinPush) === unconnectedChannel.joinPush
        }
      }

      describe(".onClose") {
        it("creates event bindings for the close event") {
          unconnectedChannel.onClose(callback: { (msg) -> Void in let _ = "asdf" })
          expect(unconnectedChannel.bindings.first?.event) == ChannelEvent.close
        }
      }

      describe(".onError") {
        it("creates event bindings for the error event") {
          unconnectedChannel.onError(callback: { (msg) -> Void in let _ = "asdf" })
          expect(unconnectedChannel.bindings.first?.event) == ChannelEvent.error
        }
      }

      describe(".on") {
        it("adds the passed in event binding to the `bindings` list") {
          unconnectedChannel.on(event: "testOn", callback: { (msg) -> Void in let _ = "asdf" })
          expect(unconnectedChannel.bindings.first?.event) == "testOn"
        }
      }

      describe(".off") {
        it("removes the passed in event binding by the passed in event name") {
          unconnectedChannel.on(event: "testOff1", callback: { (msg) -> Void in let _ = "asdf" })
          unconnectedChannel.on(event: "testOff2", callback: { (msg) -> Void in let _ = "asdf" })
          precondition(unconnectedChannel.bindings.count == 2)
          unconnectedChannel.off(event: "testOff1")
          expect(unconnectedChannel.bindings.count) == 1
          expect(unconnectedChannel.bindings.first?.event) == "testOff2"
        }
      }

      describe("`canPush`") {
        context("when `socket.isConnected` and `isJoined` are both true") {
          it("returns true") {
            mockChannel.state = ChannelState.joined
            expect(mockChannel.canPush).to(beTrue())
          }
        }

        context("when `socket.isConnected` is false") {
          it("returns false") {
            unconnectedChannel.state = ChannelState.joined
            expect(unconnectedChannel.canPush).to(beFalse())
          }
        }

        context("when `isJoined` is false") {
          expect(mockChannel.canPush).to(beFalse())
        }
      }

      describe(".push") {
        context("when channel `canPush`") {
          it("creates an instance of Push and sends it") {
            mockChannel.state = ChannelState.joined
            let testPush = mockChannel.push(event: "testPush", payload: ["k": "v"]) as! MockPush
            expect(testPush.sendCalled).to(beTrue())
          }
        }

        context("when channel can't push") {
          it("calls scheduleTimeout on the new Push instance") {
            let testPush = mockChannel.push(event: "testPush", payload: ["k": "v"]) as! MockPush
            expect(testPush.startTimeoutCalled).to(beTrue())
          }
          it("adds new Push instance to the `pushBuffer`") {
            let testPush = mockChannel.push(event: "testPush", payload: ["k": "v"])
            expect(mockConnectedSocket.pushCalled).to(beFalse())
            expect(mockChannel.pushBuffer.first) === testPush
          }
        }
      }

      describe(".leave") {
        it("changes `state` to leaving") {
          mockChannel.leave()
          expect(mockChannel.state) == ChannelState.leaving
        }

        context("when the created push gets a response, the onClose callback") {
          it("logs a leave message") {
            var kindsReceived: Array<String> = []
            var msgsReceived: Array<String> = []
            let testOptions = SocketOptions(logger: { (kind, msg, data) in
              print("appending \(kind) to thing")
              kindsReceived.append(kind)
              msgsReceived.append(msg)
            })
            let configuredSocket = Socket(endPoint: endPoint, opts: testOptions)
            let configuredChannel = MockChannel(
              topic: "test:topic", socket: configuredSocket, pushClass: MockPush.self
            )
            configuredChannel.leave() // calls MockPush.receive which triggers all callbacks
            expect(kindsReceived) == ["channel", "channel"] // once each for on "ok" and "timeout"
            expect(msgsReceived) == ["leave test:topic", "leave test:topic"]
          }

          it("calls `trigger` with message") {
            mockChannel.leave() // calls MockPush.receive which triggers all callbacks
            expect(mockChannel.triggerTimesCalled) == 2 // once each for on "ok" and "timeout"
          }
        }

        it("creates a new push and adds two `.receive` hooks to it") {
          let testPush = mockChannel.leave() as! MockPush
          expect(testPush.receivedStatuses) == ["ok", "timeout"]
        }

        it("sends the created push") {
          let testPush = mockChannel.leave() as! MockPush
          expect(testPush.sendCalled).to(beTrue())
        }

        context("when channel can't push") {
          it("calls trigger on the created push") {
            precondition(mockChannel.canPush == false)
            let testPush = mockChannel.leave() as! MockPush
            expect(testPush.triggerCalled).to(beTrue())
            expect(testPush.triggerStatus) == "ok"
          }
        }
      }
    }
  }
}

