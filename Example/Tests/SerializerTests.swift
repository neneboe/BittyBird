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
          print("couldn't pack data in test")
        }
      }

      describe(".encode(msg, callback)") {
        it("passes encoded `msg` to `callback`") {
          let callback = {(data: Data) -> Data in return data}
          let encodedMsg: Data = Serializer.encode(msg: testMsg, callback: callback)
          expect(encodedMsg) == binMsg
        }
      }

      describe(".decode(rawPayload, callback)") {
        it("passes decoded `rawPayload` to `callback`") {
          let callback = {(msg: Message) -> Message in return msg}
          let decodedMsg: Message = Serializer.decode(rawPayload: binMsg, callback: callback)
          expect(decodedMsg.topic).to(equal(testMsg.topic))
        }
      }
    }
  }
}
