//
//  BBTimer.swift
//  BittyBird
//
//  Created by Nick Eneboe on 6/27/18.
//
import Foundation

/// Creates a timer that accepts a `timerCalc` function to perform calculated timeout retries, such as exponential backoff.
open class BBTimer {
  /// Function called when timer is triggered
  private let callback: (() -> Void)
  /// Function that accepts number of tries as a parameter and returns a timer duration in seconds
  private let timerCalc: ((_ tries: Int) -> Int)
  /// The NSTimer.Timer
  var timer: Timer?
  /// Number of times the timer has been triggered
  var tries: Int

  /**
   Initializes a new instance of BBTimer with the provided callback and timerCalc functions.
   - Parameter callback: Function called when timer is triggered
   - Parameter timerCalc: Function that accepts number of tries as a parameter and returns a timer duration in seconds
   - Returns: An instance of BBTimer
   */
  init(callback: @escaping (() -> Void), timerCalc: @escaping ((_ tries: Int) -> Int)) {
    self.callback = callback
    self.timerCalc = timerCalc
    self.timer = nil
    self.tries = 0
  }

  /**
   Resets tries to 0 and stops the current timer
   - Returns: No return value
   */
  public func reset() {
    tries = 0
    clearTimeout()
  }

  /**
   Cancels any previous scheduleTimeout and schedules callback
   - Returns: No return value
   */
  public func scheduleTimeout() {
    clearTimeout()
    timer = Timer.scheduledTimer(
      timeInterval: TimeInterval(timerCalc(self.tries)),
      target: self,
      selector: #selector(onTimerTriggered),
      userInfo: nil,
      repeats: false
    )
  }

  /// Stops timer
  private func clearTimeout() {
    timer?.invalidate()
    timer = nil
  }

  /// Increment number of tries and run callback
  @objc func onTimerTriggered() {
    tries += 1
    callback()
  }
}
