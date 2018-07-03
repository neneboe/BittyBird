// https://github.com/Quick/Quick

import Quick
import Nimble
import SwiftMsgPack
@testable import BittyBird

class SerializerSpec: QuickSpec {
  override func spec() {
    describe("A Serializer") {
      let serializer = Serializer()
      let key = "key"
      let stringValue = "value"
      let testMsg1 = Message(
        topic: "topic",
        event: "event",
        payload: [key: stringValue],
        ref: "ref"
      )
      var binMsg1 = Data()

      beforeEach() {
        binMsg1 = Data()
        do {
          try binMsg1.pack(
            [
              "topic": testMsg1.topic,
              "event": testMsg1.event,
              "payload": testMsg1.payload,
              "ref": testMsg1.ref,
              "joinRef": testMsg1.joinRef as Any
            ]
          )
        } catch {
          print("Couldn't pack data in test: \(error)")
        }
      }

      // TODO: Add more contexts
      describe("#encode(msg, callback)") {
        it("passes encoded `msg` to `callback`") {
          var encodedMsg = Data()
          let callback = { (data: Data) -> Void in encodedMsg = data }
          serializer.encode(msg: testMsg1, callback: callback)
          expect(encodedMsg) == binMsg1
        }
      }

      // TODO: Add more contexts
      describe("#decode(rawPayload, callback)") {
        it("passes decoded `rawPayload` to `callback`") {
          var decodedMsg = Message(topic: "t", event: "e", payload: ["k": "v"], ref: "r") // doesn't match testMsg
          let callback = {(msg: Message) -> Void in decodedMsg = msg}
          serializer.decode(rawPayload: binMsg1, callback: callback)
          expect(decodedMsg.topic) == testMsg1.topic
          expect(decodedMsg.event) == testMsg1.event
          expect(decodedMsg.payload[key] as? String) == stringValue
          expect(decodedMsg.ref) == testMsg1.ref
          expect(decodedMsg.joinRef).to(beNil())
        }
      }
    }
  }
}
