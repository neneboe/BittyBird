//
//  ChannelTests.swift
//  BittyBird_Tests
//
//  Created by Nick Eneboe on 7/3/18.
//

import Quick
import Nimble
@testable import BittyBird

class ChannelSpec: QuickSpec {
  override func spec() {
    describe("A Channel") {
      let endPoint = "ws://localhost:4000/socket/websocket"
      var logKind: String!
      var logMsg: String!
      let socketOptions = SocketOptions(
        logger: { (kind, msg, data) in
          logKind = kind
          logMsg = msg
        }
      )
      var unconnectedSocket: Socket!
      var unconnectedChannel: MockChannel!
      var actualChannel: Channel!
      var mockConnection: MockConnection!
      var mockConnectedSocket: MockConnectedSocket!
      var mockChannel: MockChannel!

      beforeEach {
        logKind = ""
        logMsg = ""
        unconnectedSocket = Socket(endPoint: endPoint)
        mockConnection = MockConnection(url: URL(string: endPoint)!)
        mockConnectedSocket = MockConnectedSocket(connection: mockConnection, opts: socketOptions)

        actualChannel = Channel(topic: "nonmock:channel", socket: unconnectedSocket)
        unconnectedChannel = MockChannel(topic: "test:channel", socket: unconnectedSocket)
        mockChannel = MockChannel(topic: "test:topic", socket: mockConnectedSocket, pushClass: MockPush.self)
      }

      describe("initilization") {
        it("returns a channel with the correct properties") {
          let testChannel = Channel(topic: "initTest:channel", params: ["k": "v"], socket: unconnectedSocket)
          expect(testChannel.state) == ChannelState.closed
          expect(testChannel.topic) == "initTest:channel"
          expect(testChannel.params["k"] as? String) == "v"
          expect(testChannel.socket) === unconnectedSocket
          expect(testChannel.bindings.count).toNot(beNil())
          expect(testChannel.timeout) == unconnectedSocket.timeout
          expect(testChannel.joinedOnce).to(beFalse())
          expect(testChannel.joinPush).to(beAKindOf(Push.self))
          expect(testChannel.pushBuffer.count) == 0
          expect(testChannel.rejoinTimer).to(beAKindOf(BBTimer.self))
        }

        describe("sets up initial bindings") {
          context("on `joinPush` for 'ok' message with a callback that") {
            var testJoinPush: MockPush!
            var okCallback: ((Message) -> Void)!
            beforeEach {
              testJoinPush = mockChannel.joinPush as! MockPush
              okCallback = testJoinPush.receivedBindings.filter({ $0.status == "ok" }).first?.callback
              precondition(okCallback != nil)
            }
            it("sets channel state to joined") {
              precondition(mockChannel.state != ChannelState.joined)
              okCallback(Message())
              expect(mockChannel.state) == ChannelState.joined
            }
            it("resets the `rejoinTimer`") {
              mockChannel.rejoinTimer.scheduleTimeout()
              precondition(mockChannel.rejoinTimer.timer!.isValid)
              okCallback(Message())
              expect(mockChannel.rejoinTimer.timer).to(beNil())
            }
            it("sends any instances of Push in the `pushBuffer`") {
              let testPush = MockPush(channel: mockChannel, event: "pushBufferTesting", timeout: 30)
              mockChannel.pushBuffer.append(testPush)
              okCallback(Message())
              expect(testPush.sendCalled).to(beTrue())
            }
            it("empties the `pushBuffer`") {
              let testPush = MockPush(channel: mockChannel, event: "pushBufferTesting", timeout: 30)
              mockChannel.pushBuffer.append(testPush)
              okCallback(Message())
              expect(mockChannel.pushBuffer.count) == 0
            }
          }

          context("on `joinPush` for 'timeout' message with a callback that") {
            var testJoinPush: MockPush!
            var timeoutCallback: ((Message) -> Void)!
            beforeEach {
              testJoinPush = mockChannel.joinPush as! MockPush
              timeoutCallback = testJoinPush.receivedBindings.filter({ $0.status == "timeout" }).first?.callback
              precondition(timeoutCallback != nil)
            }
            it("logs a timeout message") {
              mockChannel.joinPush.ref = "jpRef" // log message will include `channel.joinRef`
              timeoutCallback(Message())
              expect(logKind) == "channel"
              expect(logMsg) == "timeout test:topic (jpRef)"
            }
            it("creates and sends a leavePush") {
              timeoutCallback(Message())
              expect(mockChannel.createAndSendLeavePushCalled).to(beTrue())
            }
            it("sets channel state to errored") {
              timeoutCallback(Message())
              expect(mockChannel.state) == ChannelState.errored
            }
            it("calls reset on `joinPush`") {
              let mockJoinPush = mockChannel.joinPush as! MockPush
              timeoutCallback(Message())
              expect(mockJoinPush.resetCalled).to(beTrue())
            }
            it("starts the `rejoinTimer`") {
              precondition(mockChannel.rejoinTimer.timer == nil)
              timeoutCallback(Message())
              expect(mockChannel.rejoinTimer.timer?.isValid).to(beTrue())
            }
          }

          context("for onClose event with a callback that") {
            func triggerTheOnCloseCallback(c: MockChannel) {
              c.trigger(msg: Message(event: ChannelEvent.close))
            }
            it("resets the `rejoinTimer`") {
              mockChannel.rejoinTimer.scheduleTimeout()
              precondition(mockChannel.rejoinTimer.timer!.isValid)
              triggerTheOnCloseCallback(c: mockChannel)
              expect(mockChannel.rejoinTimer.timer).to(beNil())
            }
            it("logs a close message") {
              mockChannel.joinPush.ref = "jpRef" // log message will include `channel.joinRef`
              triggerTheOnCloseCallback(c: mockChannel)
              expect(logKind) == "channel"
              expect(logMsg) == "close test:topic jpRef"
            }
            it("changes channel state to closed") {
              mockChannel.state = ChannelState.joined
              triggerTheOnCloseCallback(c: mockChannel)
              expect(mockChannel.state) == ChannelState.closed
            }
            it("removes self from its socket") {
              mockChannel.joinPush.ref = "jpRef"
              mockConnectedSocket.channels.append(mockChannel)
              precondition(mockConnectedSocket.channels.count == 1)
              triggerTheOnCloseCallback(c: mockChannel)
              expect(mockConnectedSocket.channels.count) == 0
            }
          }

          context("for onError event with a callback that") {
            func triggerTheOnErrorCallback(c: MockChannel) {
              c.trigger(msg: Message(event: ChannelEvent.error))
            }
            beforeEach {
              mockChannel.state = ChannelState.joined
            }
            context("when channel is in state of leaving") {
              it("does nothing") {
                mockChannel.state = ChannelState.leaving
                triggerTheOnErrorCallback(c: mockChannel)
                expect(logKind) == ""
              }
            }
            context("when channel is closed") {
              it("does nothing") {
                mockChannel.state = ChannelState.closed
                triggerTheOnErrorCallback(c: mockChannel)
                expect(logKind) == ""
              }
            }
            it("logs an error message") {
              triggerTheOnErrorCallback(c: mockChannel)
              expect(logKind) == "channel"
              expect(logMsg) == "error test:topic"
            }
            it("changes channel state to errored") {
              triggerTheOnErrorCallback(c: mockChannel)
              expect(mockChannel.state) == ChannelState.errored
            }
            it("it schedules rejoin timeout") {
              triggerTheOnErrorCallback(c: mockChannel)
              expect(mockChannel.rejoinTimer.timer?.isValid).to(beTrue())
            }
          }

          context("for reply event with a callback that") {
            it("calls `trigger`, passing the message with reply event name") {
              mockChannel.trigger(msg: Message(event: ChannelEvent.reply, ref: "testRef"))
              expect(mockChannel.triggerMsg.event) == "chan_reply_testRef"
            }
          }
        }
      }

      describe(".rejoinUntilConnected") {
        it("starts the `rejoinTimer`") {
          precondition(actualChannel.rejoinTimer.timer == nil)
          actualChannel.rejoinUntilConnected()
          expect(actualChannel.rejoinTimer.timer?.isValid).to(beTrue())
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
          precondition(actualChannel.joinedOnce == false)
          let _ = actualChannel.join()
          expect(actualChannel.joinedOnce).to(beTrue())
        }

        it("calls `rejoin`") {
          let _ = unconnectedChannel.join()
          expect(unconnectedChannel.rejoinCalled).to(beTrue())
        }

        it("returns `joinPush`") {
          let joinPush = actualChannel.join()
          expect(joinPush) === actualChannel.joinPush
        }
      }

      describe(".onClose") {
        it("creates event bindings for the close event") {
          actualChannel.onClose(callback: { (msg) -> Void in let _ = "asdf" })
          expect(actualChannel.bindings.first?.event) == ChannelEvent.close
        }
      }

      describe(".onError") {
        it("creates event bindings for the error event") {
          actualChannel.onError(callback: { (msg) -> Void in let _ = "asdf" })
          expect(actualChannel.bindings.map({ $0.event }).contains(ChannelEvent.error)).to(beTrue())
        }
      }

      describe(".on") {
        it("adds the passed in event binding to the `bindings` list") {
          actualChannel.on(event: "testOn", callback: { (msg) -> Void in let _ = "asdf" })
          expect(actualChannel.bindings.map({ $0.event }).contains("testOn")).to(beTrue())
        }
      }

      describe(".off") {
        it("removes the passed in event binding by the passed in event name") {
          actualChannel.on(event: "testOff1", callback: { (msg) -> Void in let _ = "asdf" })
          actualChannel.on(event: "testOff2", callback: { (msg) -> Void in let _ = "asdf" })
          precondition(actualChannel.bindings.map({ $0.event }).contains("testOff1"))
          precondition(actualChannel.bindings.map({ $0.event }).contains("testOff2"))
          actualChannel.off(event: "testOff1")
          expect(actualChannel.bindings.map({ $0.event }).contains("testOff1")).to(beFalse())
          expect(actualChannel.bindings.map({ $0.event }).contains("testOff2")).to(beTrue())
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
          it("returns false") {
            precondition(actualChannel.isJoined == false)
            expect(actualChannel.canPush).to(beFalse())
          }
        }
      }

      describe(".push") {
        context("when channel `canPush`") {
          it("creates an instance of Push and sends it") {
            mockChannel.state = ChannelState.joined
            precondition(mockChannel.canPush == true)
            let testPush = mockChannel.push(event: "testPush", payload: ["k": "v"]) as! MockPush
            expect(testPush.sendCalled).to(beTrue())
          }
        }

        context("when channel can't push") {
          beforeEach {
            precondition(mockChannel.canPush == false)
          }
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
            let mockLeavePush = configuredChannel.leave() as! MockPush
            mockLeavePush.receivedBindings.forEach({ $0.callback(Message()) }) // triggers all joinPush's callbacks
            expect(kindsReceived) == ["channel", "channel"] // once each for on "ok" and "timeout"
            expect(msgsReceived) == ["leave test:topic", "leave test:topic"]
          }

          it("calls `trigger` with message") {
            let mockLeavePush = mockChannel.leave() as! MockPush
            mockLeavePush.receivedBindings.forEach({ $0.callback(Message()) }) // triggers all joinPush's callbacks
            expect(mockChannel.triggerTimesCalled) == 2 // once each for on "ok" and "timeout"
          }
        }

        it("creates a new push and adds two `.receive` hooks to it") {
          let testPush = mockChannel.leave() as! MockPush
          let receivedStatuses = testPush.receivedBindings.map({ $0.status })
          expect(receivedStatuses) == ["ok", "timeout"]
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

      describe(".onMessage") {
        it("returns a message") {
          let testMsg = Message(payload: ["testing" : "onMessage"], ref: "123")
          let testReturn = mockChannel.onMessage(msg: testMsg)
          expect(testReturn.ref) == testMsg.ref
        }
      }

      describe(".isMember") {
        context("when message topic doesn't match channel topic") {
          it("returns false") {
            let testMsg = Message(topic: "test topic")
            expect(actualChannel.isMember(msg: testMsg)).to(beFalse())
          }
        }
        context("when message topic matches channel topic") {
          var testMsg: Message!
          beforeEach { testMsg = Message(topic: "nonmock:channel") }
          context("when message event is a channel lifecycle event") {
            beforeEach { testMsg.event = ChannelEvent.join }
            context("when message joinRef is not nil") {
              beforeEach { testMsg.joinRef = "some join ref" }
              context("when message joinRef is not the same as the channel's") {
                beforeEach { precondition(testMsg.joinRef != actualChannel.joinRef) }
                it("returns false") { expect(actualChannel.isMember(msg: testMsg)).to(beFalse()) }
              }
              context("when message joinRef is the same as the channel's") {
                it("returns true") {
                  testMsg.joinRef = actualChannel.joinRef
                  expect(actualChannel.isMember(msg: testMsg)).to(beTrue())
                }
              }
            }
            context("when message joinRef is nil") {
              it("returns true") {
                precondition(testMsg.joinRef == nil)
                expect(actualChannel.isMember(msg: testMsg)).to(beTrue())
              }
            }
          }
          context("when message event is not a channel lifecycle event") {
            it("returns true") {
              testMsg.event = "normal event"
              expect(actualChannel.isMember(msg: testMsg)).to(beTrue())
            }
          }
        }
      }

      describe("`joinRef`") {
        it("returns `joinPush.ref`") {
          actualChannel.joinPush.ref = "join Ref 123"
          expect(actualChannel.joinRef) == "join Ref 123"
        }
      }

      describe(".sendJoin") {
        it("changes channel state to joining") {
          actualChannel.sendJoin(timeout: actualChannel.timeout)
          expect(actualChannel.state) == ChannelState.joining
        }

        it("calls `joinPush.resend`") {
          let testPush = mockChannel.joinPush as! MockPush
          precondition(testPush.resendCalled == false)
          mockChannel.sendJoin(timeout: mockChannel.timeout)
          expect(testPush.resendCalled).to(beTrue())
        }
      }

      describe(".rejoin") {
        it("calls send join with a timeout") {
          mockChannel.rejoin()
          expect(mockChannel.sendJoinTimeoutPassed) == mockChannel.timeout
        }
      }

      describe(".trigger") {
        it("triggers the appropriate events in `bindings`") {
          var untriggeredCalled = false
          let untriggeredCallback = {(_ msg: Message) -> Void in untriggeredCalled = true }
          var boundCalled = false
          let boundCallback = {(_ msg: Message) -> Void in boundCalled = true }
          var closeCalled = false
          let closeCallback = {(_ msg: Message) -> Void in closeCalled = true }
          let boundMessage = Message(event: "runBoundCb")
          let closeMessage = Message(event: ChannelEvent.close)
          actualChannel.on(event: "runUnboundCb", callback: untriggeredCallback)
          actualChannel.on(event: "runBoundCb", callback: boundCallback)
          actualChannel.onClose(callback: closeCallback)
          actualChannel.trigger(msg: boundMessage)
          expect(boundCalled).to(beTrue())
          actualChannel.trigger(msg: closeMessage)
          expect(closeCalled).to(beTrue())
          expect(untriggeredCalled).to(beFalse())
        }
      }

      describe(".replyEventName") {
        it("takes a ref and returns a modified ref") {
          let testRef = actualChannel.replyEventName(ref: "asdf")
          expect(testRef) == "chan_reply_asdf"
        }
      }

      describe("`isClosed`, `isErrored`, `isJoined`, `isJoining`, and `isLeaving`") {
        context("when channel is closed") {
          it("`isClosed` returns true") {
            actualChannel.state = ChannelState.closed
            expect(actualChannel.isClosed).to(beTrue())
            expect(actualChannel.isErrored).to(beFalse())
            expect(actualChannel.isJoined).to(beFalse())
            expect(actualChannel.isJoining).to(beFalse())
            expect(actualChannel.isLeaving).to(beFalse())
          }
        }
        context("when channel has errored") {
          it("`isErrored` returns true") {
            actualChannel.state = ChannelState.errored
            expect(actualChannel.isClosed).to(beFalse())
            expect(actualChannel.isErrored).to(beTrue())
          }
        }
        context("when channel is joined") {
          it("`isJoined` returns true") {
            actualChannel.state = ChannelState.joined
            expect(actualChannel.isJoined).to(beTrue())
          }
        }
        context("when channel is joining") {
          it("`isJoining` returns true") {
            actualChannel.state = ChannelState.joining
            expect(actualChannel.isJoining).to(beTrue())
          }
        }
        context("when channel is being left") {
          it("`isLeaving` returns true") {
            actualChannel.state = ChannelState.leaving
            expect(actualChannel.isLeaving).to(beTrue())
          }
        }
      }

      describe(".createAndSendLeavePush") {
        it("creates and sends a leavePush") {
          let leavePush = mockChannel.createAndSendLeavePush() as? MockPush
          expect(leavePush!.sendCalled).to(beTrue())
        }
      }
    }
  }
}

