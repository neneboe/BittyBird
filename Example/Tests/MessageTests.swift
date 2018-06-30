//
//  MessageTests.swift
//  BittyBird_Tests
//
//  Created by Nick Eneboe on 6/28/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Quick
import Nimble
@testable import BittyBird

class MessageSpec: QuickSpec {
  override func spec() {
    describe("A MessageSpec") {
      it("initializes with `topic`, `event`, `payload`, `ref`, and `joinRef` properties") {
        let message = Message.init(
          topic: "topic",
          event: "event",
          payload: ["key": "value"],
          ref: "ref",
          joinRef: "joinRef"
        )
        expect(message.topic) == "topic"
        expect(message.event) == "event"
        expect(message.payload["key"] as? String) == "value"
        expect(message.ref) == "ref"
        expect(message.joinRef) == "joinRef"
      }

      it("can be initialized without `joinRef` property") {
        let message = Message(
          topic: "topic",
          event: "event",
          payload: ["key": "value"],
          ref: "ref"
        )
        expect(message.topic) == "topic"
        expect(message.event) == "event"
        expect(message.payload["key"] as? String) == "value"
        expect(message.ref) == "ref"
        expect(message.joinRef).to(beNil())
      }
    }
  }
}
