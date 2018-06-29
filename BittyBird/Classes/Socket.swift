//
//  Socket.swift
//  Pods
//
//  Created by Nick Eneboe on 6/29/18.
//

import Foundation

open class Socket {
  /// A dictionary for storing arrays of callbacks to be run on certain socket events
  var stateChangeCallbacks: Dictionary <String, Array<() -> Void>>
//  public var timeout: Int
//  public var reconnectAfterSeconds: Int

  init(opts: SocketOptions = SocketOptions()) {
    self.stateChangeCallbacks = ["open": [], "close": [], "error": [], "message": []]
  }
}
