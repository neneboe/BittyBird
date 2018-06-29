// https://github.com/Quick/Quick

import Quick
import Nimble
@testable import BittyBird

class BBTimerSpec: QuickSpec {
  override func spec() {
    describe("A BBTimer") {
      var callbackTriggered = false
      let callback = {() -> Void in callbackTriggered = true}
      let timerCalc = {(tries: Int) -> Int in return 0}

      beforeEach {
        callbackTriggered = false
      }
  
      it("initializes with `timer` and `tries` properties") {
        let bbtimer = BBTimer(callback: callback, timerCalc: timerCalc)
        expect(bbtimer.timer).to(beNil())
        expect(bbtimer.tries) == 0
      }

      describe("#reset") {
        it("sets `tries` back to 0") {
          let bbtimer = BBTimer(callback: callback, timerCalc: timerCalc)
          bbtimer.tries = 1
          precondition(bbtimer.tries == 1)
          bbtimer.reset()
          expect(bbtimer.tries) == 0
        }

        it("clears any current timers") {
          let bbtimer = BBTimer(callback: callback, timerCalc: timerCalc)
          bbtimer.timer = Timer.scheduledTimer(
            timeInterval: 5,
            target: self,
            selector: #selector(self.timerStub),
            userInfo: nil,
            repeats: false
          )
          precondition(bbtimer.timer != nil)
          bbtimer.reset()
          expect(bbtimer.timer).to(beNil())
        }
      }

      describe("#scheduledTimeout") {
        it("clears any current timers and schedules a timer") {
          let bbtimer = BBTimer(callback: callback, timerCalc: timerCalc)
          let existingTimer = Timer.scheduledTimer(
            timeInterval: 5,
            target: self,
            selector: #selector(self.timerStub),
            userInfo: nil,
            repeats: false
          )
          bbtimer.timer = existingTimer
          bbtimer.scheduleTimeout()
          expect(bbtimer.timer) != existingTimer
          bbtimer.reset()
        }

        context("when a timer is triggered") {
          it("increments `tries`") {
            let bbtimer = BBTimer(callback: callback, timerCalc: timerCalc)
            bbtimer.scheduleTimeout()
            expect(bbtimer.tries).toEventually(equal(1))
          }

          it("runs `callback`") {
            let bbtimer = BBTimer(callback: callback, timerCalc: timerCalc)
            bbtimer.scheduleTimeout()
            expect(callbackTriggered).toEventually(beTrue())
          }
        }
      }
    }
  }

  @objc func timerStub() {
    ()
  }
}
