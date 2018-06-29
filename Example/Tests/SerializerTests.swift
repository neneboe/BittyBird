// https://github.com/Quick/Quick

import Quick
import Nimble
import SwiftMsgPack
@testable import BittyBird

class SerializerSpec: QuickSpec {
  override func spec() {
    describe("A Serializer") {
      let key = "key"
      let testMsg = Message(
        topic: "topic",
        event: "event",
        payload: [key: "value"],
        ref: "ref"
      )
      var binMsg = Data()

      beforeEach() {
        binMsg = Data()
        do {
          try binMsg.pack(
            [
              "topic": testMsg.topic,
              "event": testMsg.event,
              "payload": testMsg.payload,
              "ref": testMsg.ref,
              "joinRef": testMsg.joinRef as Any
            ]
          )
        } catch {
          print("Couldn't pack data in test: \(error)")
        }
      }

      describe(".encode(msg, callback)") {
        it("passes encoded `msg` to `callback`") {
          var encodedMsg = Data()
          let callback = {(data: Data) -> Void in encodedMsg = data}
          Serializer.encode(msg: testMsg, callback: callback)
          expect(encodedMsg) == binMsg
        }
      }

      describe(".decode(rawPayload, callback)") {
        it("passes decoded `rawPayload` to `callback`") {
          var decodedMsg = Message(topic: "t", event: "e", payload: ["k": "v"], ref: "r") // doesn't match testMsg
          let callback = {(msg: Message) -> Void in decodedMsg = msg}
          Serializer.decode(rawPayload: binMsg, callback: callback)
          expect(decodedMsg.topic) == testMsg.topic
          expect(decodedMsg.event) == testMsg.event
          expect(decodedMsg.payload) == testMsg.payload
          expect(decodedMsg.ref) == testMsg.ref
          expect(decodedMsg.joinRef).to(beNil())
        }
      }
    }
  }
}
