// https://github.com/Quick/Quick

import Quick
import Nimble
@testable import BittyBird

class BBTimerSpec: QuickSpec {
  override func spec() {
    describe("A BBTimer") {
      var callbackTriggered = false
      var callback = {() -> Void in callbackTriggered = true}
      var timerCalc = {(tries: Int) -> Int in return 1}

      beforeEach {
        callbackTriggered = false
      }

      it("has `timer` and `tries` properties") {
        let bbtimer = BBTimer.init(callback: callback, timerCalc: timerCalc)
        expect(bbtimer.timer).to(beNil())
        expect(bbtimer.tries) == 0
      }
    }
  }
}
