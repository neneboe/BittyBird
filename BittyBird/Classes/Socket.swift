//
//  Socket.swift
//  Pods
//
//  Created by Nick Eneboe on 6/29/18.
//

import Foundation
import Starscream

open class Socket {
  /// Timeout in seconds to trigger push timeouts
  public var timeout: Int
  /// Configurable, optional function that returns the reconnect interval in seconds
  public var reconnectAfterSeconds: ((_ tries: Int) -> Int)

  /// String of the URL of the server websocket end point
  var endPoint: String
  /// Configurable, optional websocket transport - uses Starscream WebSocket by default
  var transport: Any
  /// Configurable, optional interval in seconds to send heartbeat message
  var heartbeatIntervalSeconds: Int
  /// Configurable, optional logger function, defaults to noop
  var logger: ((_ kind: String, _ msg: String, _ data: Any) -> Void)
  /// Configurable, optional params passed to server when connecting
  var params: Dictionary <String, Any>

  /// List of instances of Channel that are connected via the socket
  var channels: Array <Channel> = []
  /// Instance of Timer that sends out a heartbeat message on trigger
  var heartbeatTimer: Timer? = nil
  /// Ref counter for the last heartbeat that was sent
  var pendingHeartbeatRef: String? = nil
  /// Timer to use when attempting to reconnect
  private var reconnectTimer: BBTimer!
  /// Ref counter for each Message instance passed through the socket
  var ref = 0
  /// Buffer for callbacks that will send messages once the socket has connected
  var sendBuffer: Array <() -> Void> = []
  /// Dictionary for storing arrays of callbacks to be run on certain socket events
  var stateChangeCallbacks: Dictionary <String, Array <() -> Void>> = [
    "open": [], "close": [], "error": [], "message": []
  ]

  /**
   Initializes a new instance of Socket

   - Parameter endPoint: Server's web socket address
   - Parameter opts: A SocketOptions instance that can be used to configure some socket properties
   - Returns: An instance of Socket
   */
  init(endPoint: String, opts: SocketOptions = SocketOptions()) {
    self.stateChangeCallbacks = ["open": [], "close": [], "error": [], "message": []]
    self.timeout = opts.timeout ?? 10
    self.reconnectAfterSeconds = opts.reconnectAfterSeconds ?? {(tries: Int) -> Int in
      guard tries < 4 else { return 10 }
      return [1, 2, 5, 10][tries]
    }
    self.endPoint = endPoint
    self.transport = opts.transport.self ?? WebSocket.self
    self.heartbeatIntervalSeconds = opts.heartbeatIntervalSeconds ?? 30
    self.logger = opts.logger ?? {(kind: String, msg: String, data: Any) in ()}
    self.params = opts.params ?? [:]
    self.reconnectTimer = BBTimer(callback: {
      self.disconnect({ self.connect() })
    }, timerCalc: reconnectAfterSeconds)
  }

  func connect() {

  }

  public func disconnect(_ callback: (() -> Void)? = nil) {
    callback?()
  }
}
