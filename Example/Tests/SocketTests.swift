//
//  SocketTests.swift
//  BittyBird_Tests
//
//  Created by Nick Eneboe on 6/29/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Quick
import Nimble
@testable import BittyBird

class SocketSpec: QuickSpec {
  override func spec() {
    describe("A Socket") {
      it("initializes with `timeout` and `reconnectAfterMs` properties") {
        let socket = Socket()
        expect(socket.timeout).notTo(beNil())
        expect(socket.reconnectAfterSeconds).notTo(beNil())
      }
    }
  }
}
