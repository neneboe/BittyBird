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
  /// The timeout in seconds to trigger push timeouts
  public var timeout: Int
  /// The optional function that returns the reconnect interval in seconds
  public var reconnectAfterSeconds: ((_ tries: Int) -> Int)

  /**
   Initializes a new instance of Socket

   - Parameter endPoint: Server's web socket address
   - Parameter opts: A SocketOptions instance that can be used to configure some socket properties
   - Returns: An instance of Socket
   */
  init(opts: SocketOptions = SocketOptions()) {
    self.stateChangeCallbacks = ["open": [], "close": [], "error": [], "message": []]
    self.timeout = opts.timeout ?? 10
    self.reconnectAfterSeconds = opts.reconnectAfterSeconds ?? {(tries: Int) -> Int in
      guard tries < 4 else { return 10 }
      return [1, 2, 5, 10][tries]
    }
  }
}
