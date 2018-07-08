//
//  PushTests.swift
//  BittyBird_Tests
//
//  Created by Nick Eneboe on 7/6/18.
//

import Quick
import Nimble
@testable import BittyBird

class PushSpec: QuickSpec {
  override func spec() {
    describe("A Push") {
      let endPoint = "ws://localhost:4000/socket/websocket"
      let defaultTimeout = 30
      var mockConnection: MockConnection!
      var connectedSocket: MockConnectedSocket!
      var connectedChannel: MockChannel!
      var realPush: Push!
      var mockPush: MockPush!

      beforeEach {
        mockConnection = MockConnection(url: URL(string: endPoint)!)
        connectedSocket = MockConnectedSocket(connection: mockConnection)
        connectedChannel = MockChannel(topic: "mockchannel:forpushtests", socket: connectedSocket)
        realPush = Push(channel: connectedChannel, event: "realPushEvent", timeout: defaultTimeout)
        mockPush = MockPush(channel: connectedChannel, event: "mockPushEvent", timeout: defaultTimeout)
      }
      describe("initializes") {
        it("with the correct properties") {
          let testPush = Push(channel: connectedChannel, event: "testPush", timeout: defaultTimeout)
          expect(testPush.channel).toNot(beNil())
          expect(testPush.event).toNot(beNil())
          expect(testPush.payload).toNot(beNil())
          expect(testPush.receivedResp).to(beNil())
          expect(testPush.timeout).toNot(beNil())
          expect(testPush.timeoutTimer).to(beNil())
          expect(testPush.recHooks.count) == 0
          expect(testPush.sent).to(beFalse())
          expect(testPush.ref).toNot(beNil())
        }
      }

      describe(".resend") {
        it("sets `timeout` to passed in timeout") {
          realPush.resend(timeout: defaultTimeout - 5)
          expect(realPush.timeout) == defaultTimeout - 5
        }

        it("calls `reset` on self") {
          mockPush.resend(timeout: defaultTimeout)
          expect(mockPush.resetCalled).to(beTrue())
        }

        it("calls `send` on self") {
          mockPush.resend(timeout: defaultTimeout)
          expect(mockPush.sendCalled).to(beTrue())
        }
      }

      describe(".send") {
        context("when push has timed out") {
          it("does nothing") {
            realPush.receivedResp = Message(event: "test timeout", payload: ["status": "timeout"])
            precondition(realPush.hasReceived(status: "timeout") == true)
            realPush.send()
            expect(realPush.timeoutTimer).to(beNil())
          }
        }

        it("calls `startTimeout`") {
          realPush.send()
          expect(realPush.timeoutTimer?.isValid).to(beTrue())
        }

        it("sets `sent` to true") {
          precondition(realPush.sent == false)
          realPush.send()
          expect(realPush.sent).to(beTrue())
        }

        it("pushes a new messsage to socket") {
          realPush.send()
          expect(connectedSocket.pushCalled).to(beTrue())
        }
      }

      describe(".receive") {
        var callbackMsg: Message!
        let callback = { (msg) -> Void in callbackMsg = msg }
        let testMsg = Message(event: "testing .receive", payload: ["status": "testReceive"])

        beforeEach {
          callbackMsg = Message()
        }

        it("can be chained") {
          var callback1Run = false
          var callback2Run = false
          realPush
            .receive(status: "testStatus") { _ in callback1Run = true }
            .receive(status: "antoherStaus") { (_ msg) in callback2Run = true }
          realPush.recHooks.forEach({ $0.callback(Message()) })
          expect(callback1Run).to(beTrue())
          expect(callback2Run).to(beTrue())
        }

        context("when push has already received the response message with the passed in status") {
          it("runs the callback immediately before adding bindings to `recHooks`") {
            realPush.receivedResp = testMsg
            precondition(realPush.hasReceived(status: "testReceive") == true)
            realPush.receive(status: "testReceive", callback: callback)
            expect(callbackMsg.event) == testMsg.event
            expect(realPush.recHooks.map({ $0.status }).contains("testReceive")).to(beTrue())
          }
        }

        context("when push has not received the response message with the passed in status") {
          it("adds status and callback to `recHooks` without calling callback") {
            precondition(realPush.hasReceived(status: "testReceive") == false)
            realPush.receive(status: "testReceive", callback: callback)
            expect(callbackMsg.event) == ""
            let cbMessage = Message(event: "cb message")
            realPush.recHooks.filter({ $0.status == "testReceive" }).first!.callback(cbMessage)
            expect(callbackMsg.event) == "cb message"
          }
        }
      }

      describe(".reset") {
        it("calls `cancelRefEvent`") {
          mockPush.reset()
          expect(mockPush.cancelRefEventCalled).to(beTrue())
        }

        it ("empties `ref`") {
          realPush.ref = "asdf"
          realPush.reset()
          expect(realPush.ref) == ""
        }

        it ("clears `refEvent`") {
          realPush.refEvent = "asdf"
          realPush.reset()
          expect(realPush.refEvent).to(beNil())
        }

        it("clears `receivedResp`") {
          realPush.receivedResp = Message()
          realPush.reset()
          expect(realPush.receivedResp).to(beNil())
        }

        it("sets `sent` to false") {
          realPush.sent = true
          realPush.reset()
          expect(realPush.sent).to(beFalse())
        }
      }

      describe(".matchReceive") {
        it("triggers the callbacks in `recHooks` with statuses that match passed in status") {
          var callback1Msg = Message()
          var callback2Msg = Message()
          let callback1 = { (msg) -> Void in callback1Msg = msg }
          let callback2 = { (msg) -> Void in callback2Msg = msg }
          let testMsg = Message(event: "test matchReceive")
          realPush.recHooks = [
            (status: "run cb1", callback: callback1), (status: "run cb2", callback: callback2)
          ]
          realPush.matchReceive(status: "run cb2", msg: testMsg)
          expect(callback1Msg.event) == ""
          expect(callback2Msg.event) == "test matchReceive"
        }
      }

      describe(".cancelRefEvent") {
        context("when the push has a refEvent") {
          it("calls `channel.off` with push's refEvent") {
            realPush.refEvent = "testRefEvent"
            precondition(realPush.refEvent != nil)
            realPush.cancelRefEvent()
            expect(connectedChannel.offCalledWith) == realPush.refEvent
          }
        }

        context("when the push has no refEvent") {
          it("does nothing") {
            precondition(realPush.refEvent == nil)
            realPush.cancelRefEvent()
            expect(connectedChannel.offCalled).to(beFalse())
          }
        }
      }

      describe(".cancelTimeout") {
        it("invalidates and resets the `timeoutTimer`") {
          realPush.startTimeout()
          precondition(realPush.timeoutTimer?.isValid == true)
          realPush.cancelTimeout()
          expect(realPush.timeoutTimer).to(beNil())
        }
      }

      describe(".startTimeout") {
        context("when push already has a `timeoutTimer`") {
          it("cancels the existing `timeoutTimer`") {
            mockPush.startTimeout()
            precondition(mockPush.timeoutTimer != nil)
            mockPush.startTimeout()
            expect(mockPush.cancelTimeoutCalled).to(beTrue())
          }
        }

        it("sets `ref` and `eventRef`") {
          realPush.startTimeout()
          expect(realPush.ref) != ""
          expect(realPush.refEvent).toNot(beNil())
        }

        context("registers bindings with channel for on `refEvent` with a callback that") {
          var testRefEvent: String!
          var testMsg: Message!

          beforeEach {
            mockPush.startTimeout()
            testRefEvent = mockPush.refEvent
            testMsg = Message(event: testRefEvent, ref: "test Message ref")
          }

          it("unregisters itself in channel bindings with `cancelRefEvent`") {
            connectedChannel.trigger(msg: testMsg)
            expect(mockPush.cancelRefEventCalled).to(beTrue())
          }

          it("cancels the timeout") {
            connectedChannel.trigger(msg: testMsg)
            expect(mockPush.cancelTimeoutCalled).to(beTrue())
          }

          it("sets `receivedResp` to passed in msg") {
            connectedChannel.trigger(msg: testMsg)
            expect(mockPush.receivedResp?.event) == testRefEvent
            expect(mockPush.receivedResp?.ref) == "test Message ref"
          }
          context("when there is a status in the message payload") {
            it("calls `matchReceive`") {
              let testMsgWithStatus = Message(
                event: testRefEvent, payload: ["status": "theStatus"], ref: "test Message ref"
              )
              connectedChannel.trigger(msg: testMsgWithStatus)
              expect(mockPush.matchReceiveCalled).to(beTrue())
            }
          }
          context("when there is no status in the message payload") {
            it("doesn't call `matchReceive`") {
              connectedChannel.trigger(msg: testMsg)
              expect(mockPush.matchReceiveCalled).to(beFalse())
            }
          }
        }
      }

      describe(".hasReceived") {
        context("when there is a `receivedResp` and its status equals the passed in status") {
          it("returns true") {
            realPush.receivedResp = Message(
              event: "testing hasReceived", payload: ["status": "testStatus"]
            )
            expect(realPush.hasReceived(status: "testStatus")).to(beTrue())
          }
        }

        context("when there is a `receivedResp` but its status is not the same as passed in status") {
          it("returns false") {
            realPush.receivedResp = Message(
              event: "testing hasReceived", payload: ["status": "testStatus"]
            )
            expect(realPush.hasReceived(status: "notTestStatus")).to(beFalse())
          }
        }

        context("when there is no `receivedResp`") {
          it("returns false") {
            precondition(realPush.receivedResp == nil)
            expect(realPush.hasReceived(status: "anything")).to(beFalse())
          }
        }
      }

      describe(".trigger") {
        context("when there is no `refEvent`") {
          it("does nothing") {
            realPush.trigger(status: "aStatus", payload: [:])
            expect(connectedChannel.triggerCalled).to(beFalse())
          }
        }

        context("where there is a `refEvent`" ) {
          it("creates a new Message and sends it to `channel.trigger`") {
            realPush.refEvent = "testRefEvent"
            realPush.trigger(status: "testTrigger", payload: ["k": "v"])
            expect(connectedChannel.triggerMsg.ref) == "testRefEvent"
            expect(connectedChannel.triggerMsg.payload["status"] as? String) == "testTrigger"
            expect(connectedChannel.triggerMsg.payload["k"] as? String) == "v"
          }
        }
      }

      describe(".onTimeoutTriggered") {
        it("calls `trigger` with 'timeout' as status") {
          mockPush.onTimeoutTriggered()
          expect(mockPush.triggerCalled).to(beTrue())
          expect(mockPush.triggerStatus) == "timeout"
        }
      }
    }
  }
}
