//
//  Socket.swift
//  Pods
//
//  Created by Nick Eneboe on 6/29/18.
//

import Foundation
import Starscream

/// A web socket connection to the server over which channels are multiplexed
open class Socket {
  /// API Version - matches phoenix.js
  static let VSN = "2.0.0"
  /// Default heartbeat interval in seconds
  static let HEARTBEATINTERVAL = 30
  /// Default function to use for reconnectAfterSeconds
  static let RECONNECTAFTERFUNC = { (tries: Int) -> Int in
    guard tries < 4 else { return 10 }
    return [1, 2, 5, 10][tries]
  }
  /// Default timeout in seconds for push timeouts
  static let TIMEOUT = 10


  /// Configurable, optional function that returns the reconnect interval in seconds
  public var reconnectAfterSeconds: ((_ tries: Int) -> Int)
  /// Configurable, optional timeout in seconds to trigger push timeouts
  public var timeout: Int

  /// Configurable, optional interval in seconds to send heartbeat message
  public let heartbeatIntervalSeconds: Int
  /// Configurable, optional logger function, defaults to noop
  public let logger: ((_ kind: String, _ msg: String, _ data: Any) -> Void)
  /// Configurable, optional params passed to server when connecting
  public let params: Dictionary <String, Any>

  // TODO: Configurable, optional websocket transport - uses Starscream WebSocket by default
  //  private let transport: Any
  /// The Starscream web socket connection
  public let connection: WebSocket
  /// List of instances of Channel that are connected via the socket
  public var channels: Array <Channel> = []
  /// The URL, including the params, of the socket server
  public var endPointURL: URL
  /// Instance of Timer that sends out a heartbeat message on trigger
  public var heartbeatTimer: Timer? = nil
  /// Ref counter for the last heartbeat that was sent
  private var pendingHeartbeatRef: String? = nil
  /// Timer to use when attempting to reconnect
  private var reconnectTimer: BBTimer!
  /// Ref counter for each Message instance passed through the socket
  private var ref = 0
  /// Buffer for callbacks that will send messages once the socket has connected
  private var sendBuffer: Array <() -> Void> = []
  /// Dictionary for storing arrays of callbacks to be run on certain socket events
  private var stateChangeCallbacks: Dictionary <String, Array <() -> Void>> = [
    "open": [], "close": [], "error": [], "message": []
  ]

  /**
   Initializes a new instance of Socket

   - Parameter connection: A WebSocket connection
   - Parameter opts: A SocketOptions instance that can be used to configure some socket properties
   - Returns: An instance of Socket
   */
  public init(connection: WebSocket, opts: SocketOptions = SocketOptions()) {
    self.connection = connection
    self.endPointURL = connection.currentURL
    self.heartbeatIntervalSeconds = opts.heartbeatIntervalSeconds ?? Socket.HEARTBEATINTERVAL
    self.logger = opts.logger ?? { (kind: String, msg: String, data: Any) in () }
    self.params = opts.params ?? [:]
    self.reconnectAfterSeconds = opts.reconnectAfterSeconds ?? Socket.RECONNECTAFTERFUNC
    self.timeout = opts.timeout ?? Socket.TIMEOUT
    self.reconnectTimer = BBTimer(callback: {
      self.disconnect({ self.connect() })
    }, timerCalc: reconnectAfterSeconds)
  }

  /**
   Initializes a new instance of Socket

   - Parameter endPoint: Server's web socket address
   - Parameter opts: A SocketOptions instance that can be used to configure some socket properties
   - Returns: An instance of Socket
   */
  public convenience init(endPoint: String, opts: SocketOptions = SocketOptions()) {
    let urlWithParams = Socket.buildURLWithParams(endPoint: endPoint, params: opts.params)
    let connection = WebSocket(url: urlWithParams)
    self.init(connection: connection, opts: opts)
  }

  /**
   The protocol of the socket: either "wss" or "ws"

   - Returns: Either "wss" or "ws"
   */
  public var socketProtocol: String {
    get {
      let wssRegexPattern = "^wss:.+"
      let wssRegex = try! NSRegularExpression(pattern: wssRegexPattern, options: .caseInsensitive)
      let location = "\(connection.currentURL)"
      let matches = wssRegex.matches(in: location, range: NSMakeRange(0, location.utf16.count))
      return matches.isEmpty ? "ws" : "wss"
    }
  }

  /// Disconnects the socket and triggers optional callback
  open func disconnect(_ callback: (() -> Void)? = nil) {
    connection.delegate = nil
    connection.disconnect(forceTimeout: nil, closeCode: CloseCode.normal.rawValue)
    callback?()
  }

  /// Connects the socket to server
  open func connect() {
    guard !connection.isConnected else { return }
    connection.delegate = self
    connection.connect()
  }

  open func log(kind: String, msg: String, data: Any) {
    logger(kind, msg, data)
  }

  /// Called when the underlying Websocket connects to it's host
  private func onConnectionOpen() {

  }

  private func onConnectionClosed() {

  }

  private func onConnectionError(_ error: Error) {

  }

  private func onConnectionMessage(_ rawMessage: String) {

  }

  /**
   Formats a url with params

   - Parameter endPoint: A URL String
   - Parameter params: Optional Dictionary of params
   - Returns: A URL instance
   */
  private class func buildURLWithParams(endPoint: String, params: Dictionary <String, Any>?) -> URL {
    let baseURL = URL(string: endPoint)!
    var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
    var urlParams = params ?? [:]
    urlParams["vsn"] = Socket.VSN
    urlComponents!.queryItems = urlParams.map{ return URLQueryItem(name: "\($0)", value: "\($1)") }
    return urlComponents!.url!
  }
}

extension Socket: WebSocketDelegate {
  public func websocketDidConnect(socket: WebSocketClient) {
    self.onConnectionOpen()
  }

  public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
    guard let error = error else {
      self.onConnectionClosed()
      return }

    self.onConnectionError(error)
  }

  public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
    self.onConnectionMessage(text)
  }

  public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
    /* no-op */
  }
}
