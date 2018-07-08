//
//  Socket.swift
//  Pods
//
//  Created by Nick Eneboe on 6/29/18.
//

import Starscream

/// Stores callbacks to be triggered on connection events
public struct StateChangeCallbacks {
  var open: Array<() -> Void> = []
  var close: Array<() -> Void> = []
  var error: Array<() -> Void> = []
  var message: Array<() -> Void> = []
}

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
  public let logger: ((_ kind: String, _ msg: String, _ data: Any?) -> Void)
  /// Configurable, optional params passed to server when connecting
  public let params: Dictionary<String, Any>

  // TODO: Configurable, optional websocket transport - uses Starscream WebSocket by default
  //  private let transport: Any
  /// The Starscream web socket connection
  open let connection: WebSocket
  /// The function used for encoding
  open let serializer: Serializer

  /// List of instances of Channel that are connected via the socket
  public var channels: Array<Channel> = []
  /// The URL, including the params, of the socket server
  public var endPointURL: URL
  /// Instance of Timer that sends out a heartbeat message on trigger
  public var heartbeatTimer: Timer? = nil
  /// Ref counter for the last heartbeat that was sent
  open var pendingHeartbeatRef: String? = nil
  /// Timer to use when attempting to reconnect
  public var reconnectTimer: BBTimer!
  /// Ref counter for each Message instance passed through the socket
  open var ref: UInt64 = UInt64.min // 0
  /// Buffer for callbacks that will send messages once the socket has connected
  public var sendBuffer: Array<() -> Void> = []
  /// Disable sending heartbeats by setting this to true.
  public var skipHeartbeat = false
  /// Dictionary for storing arrays of callbacks to be run on certain socket events
  open var stateChangeCallbacks: StateChangeCallbacks = StateChangeCallbacks()

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
    self.logger = opts.logger ?? { (kind: String, msg: String, data: Any?) in () } // no-op
    self.params = opts.params ?? [:]
    self.reconnectAfterSeconds = opts.reconnectAfterSeconds ?? Socket.RECONNECTAFTERFUNC
    self.timeout = opts.timeout ?? Socket.TIMEOUT
    self.serializer = opts.serializer ?? Serializer()
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

  /// The protocol of the socket: either "wss" or "ws"
  open var socketProtocol: String {
    let wssRegexPattern = "^wss:.+"
    let wssRegex = try! NSRegularExpression(pattern: wssRegexPattern, options: .caseInsensitive)
    let location = "\(connection.currentURL)"
    let matches = wssRegex.matches(in: location, range: NSMakeRange(0, location.utf16.count))
    return matches.isEmpty ? "ws" : "wss"
  }

  /// Disconnects the socket and triggers optional callback
  open func disconnect(_ callback: (() -> Void)? = nil) {
    connection.delegate = nil
    connection.disconnect(forceTimeout: nil, closeCode: CloseCode.normal.rawValue)
    callback?()
  }

  /// Connects the socket to server
  open func connect() {
    guard !isConnected else { return }
    connection.delegate = self
    connection.connect()
  }

  /**
   Logs the message. You may override this method or pass a logger via the SocketOptions in initialization
   to customize this.

   - Parameter kind: The kind of message, E.g. "push", "receive", etc
   - Parameter msg: The name of the message
   - Parameter data: The message data
   */
  open func log(kind: String, msg: String, data: Any? = nil) {
    logger(kind, msg, data)
  }

  /**
   Registers callbacks for connection events
   Example:
      socket.onOpen { [unowned self] in print("Socket Connection Opened") }

   - Parameter callback: Callback to register
   */
  open func onOpen(callback: @escaping () -> Void) { stateChangeCallbacks.open.append(callback) }
  open func onClose(callback: @escaping () -> Void) { stateChangeCallbacks.close.append(callback) }
  open func onError(callback: @escaping () -> Void) { stateChangeCallbacks.error.append(callback) }
  open func onMessage(callback: @escaping () -> Void) { stateChangeCallbacks.message.append(callback) }


  /// Called when `connection` connects to host
  open func onConnOpen() {
    self.log(kind: "transport", msg: "Connected to \(connection.currentURL)")
    self.flushSendBuffer()
    self.reconnectTimer.reset()
    if !skipHeartbeat {
      heartbeatTimer?.invalidate()
      heartbeatTimer = Timer.scheduledTimer(
        timeInterval: TimeInterval(heartbeatIntervalSeconds),
        target: self,
        selector: #selector(sendHeartbeat),
        userInfo: nil,
        repeats: true
      )
    }
    stateChangeCallbacks.open.forEach({ $0() })
  }

  /// Called when `connection` closes
  open func onConnClose() {
    log(kind: "transport", msg: "close")
    triggerChanError()
    heartbeatTimer?.invalidate()
    reconnectTimer.scheduleTimeout()
    stateChangeCallbacks.close.forEach({ $0() })
  }

  /**
   Called when error is sent over `connection`

   - Parameter error: The error message
   */
  open func onConnError(error: Any?) {
    let errorMsg = error ?? ""
    log(kind: "transport", msg: "error", data: "\(errorMsg)")
    triggerChanError()
    stateChangeCallbacks.error.forEach({ $0() })
  }

  /// Pushes an error message out to every channel connected over the socket
  open func triggerChanError() {
    let errorMessage = Message(event: "error")
    channels.forEach({ $0.trigger(msg: errorMessage) })
  }

  /// Whether the connection is connected
  open var isConnected: Bool { return connection.isConnected }

  /**
   Removes the Channel from the socket. This does not cause the channel to
   inform the server that it is leaving. You should call channel.leave() first.

   - Parameter channel: The channel to remove from the socket
   */
  open func remove(channel: Channel) {
    channels = channels.filter({ $0.joinRef != channel.joinRef })
  }

  /**
   Creates a new channel and adds it to `channels`

   - Parameter topic: The channel's topic. E.g. "room:lobby"
   - Parameter chanParams: Params sent to server when channel tries to join
   - Returns: A new Channel instance
   */
  open func channel(topic: String, chanParams: Dictionary<String, Any>? = nil) -> Channel {
    let chan = Channel(topic: topic, params: chanParams, socket: self)
    channels.append(chan)
    return chan
  }

  /**
   Push a message to the server

   - Parameter msg: An instance of Message
   */
  open func push(msg: Message) {
    let callback = { ()
      self.serializer.encode(msg: msg, callback: { (data) -> Void in
        self.connection.write(data: data)
      })
    }
    log(
      kind: "push",
      msg: "\(msg.topic) \(msg.event) (\(msg.joinRef ?? ""), \(msg.ref))",
      data: msg.payload
    )
    if isConnected { callback() }
    else { self.sendBuffer.append(callback) }
  }

  /**
   Get next message ref, accounting for overflows
   - Returns: The next message ref as String
   */
  open func makeRef() -> String {
    let newRef = ref + 1
    ref = (newRef == UInt64.max) ? 0 : newRef
    return String(newRef)
  }

  /**
   Attempts to reconnect if there's an old `pendingHeartbeatRef`, otherwise
   pushes a heartbeat message to server
   */
  @objc func sendHeartbeat() {
    guard isConnected else { return }
    if pendingHeartbeatRef == nil {
      pendingHeartbeatRef = makeRef()
      push(msg: Message(
        topic: "phoenix", event: ChannelEvent.heartbeat, ref: pendingHeartbeatRef!
      ))
    } else {
      pendingHeartbeatRef = nil
      log(kind: "transport", msg: "Heartbeat timeout. Attempting to re-establish connection...")
      connection.disconnect()
    }
  }

  /// Triggers and clears any callbacks stored in the `sendBuffer`
  open func flushSendBuffer() {
    guard isConnected && sendBuffer.count > 0 else { return }
    sendBuffer.forEach({ $0() })
    sendBuffer = []
  }

  /// Called when connection receives a data message
  open func onConnMessage(rawMessage: Data) {
    serializer.decode(rawPayload: rawMessage) { (msg) in
      log(
        kind: "receive",
        msg: "\(msg.payload["status"] ?? "") \(msg.topic) \(msg.event) \(msg.ref)",
        data: msg.payload
      )
      channels.filter({ $0.isMember(msg: msg) }).forEach({ $0.trigger(msg: msg) })
      stateChangeCallbacks.message.forEach({ $0() })

      if msg.ref == pendingHeartbeatRef {
        log(kind: "transport", msg: "Received pending heartbeat")
        pendingHeartbeatRef = nil
      }
    }
  }

  /// This should't get called if you're using MessagePack, but if you
  /// swap in a json serialzer it will.
  open func onConnMessage(rawMessage: String) {
    // no-op
  }


  /**
   Formats a url with params

   - Parameter endPoint: A URL String
   - Parameter params: Optional Dictionary of params
   - Returns: A URL instance
   */
  private class func buildURLWithParams(endPoint: String, params: Dictionary<String, Any>?) -> URL {
    let baseURL = URL(string: endPoint)!
    var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
    var urlParams = params ?? [:]
    urlParams["vsn"] = Socket.VSN
    urlComponents!.queryItems = urlParams.map{ return URLQueryItem(name: "\($0)", value: "\($1)") }
    return urlComponents!.url!
  }
}

extension Socket: WebSocketDelegate {
  open func websocketDidConnect(socket: WebSocketClient) {
    onConnOpen()
  }

  open func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
    if error != nil {
      onConnError(error: error)
    } else {
      onConnClose()
    }
  }

  open func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
    onConnMessage(rawMessage: text)
  }

  open func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
    onConnMessage(rawMessage: data)
  }
}
